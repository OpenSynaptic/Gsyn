// Reflexive rules engine
import 'dart:async';
import 'dart:convert';
import 'package:opensynaptic_dashboard/data/models/models.dart';
import 'package:opensynaptic_dashboard/data/repositories/repositories.dart';
import 'package:opensynaptic_dashboard/protocol/codec/packet_builder.dart';
import 'package:opensynaptic_dashboard/protocol/transport/transport_manager.dart';
import 'package:opensynaptic_dashboard/protocol/models/device_message.dart';

class RulesEngine {
  final RuleRepository _ruleRepo;
  final AlertRepository _alertRepo;
  final OperationLogRepository _logRepo;
  final TransportManager _transport;

  StreamSubscription? _sub;
  final Map<int, DateTime> _lastTriggered = {}; // ruleId → last trigger time

  RulesEngine({
    required RuleRepository ruleRepo,
    required AlertRepository alertRepo,
    required OperationLogRepository logRepo,
    required TransportManager transport,
  }) : _ruleRepo = ruleRepo,
       _alertRepo = alertRepo,
       _logRepo = logRepo,
       _transport = transport;

  /// Start listening to the message stream.
  void start() {
    _sub?.cancel();
    _sub = _transport.messageStream.listen(_onMessage);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _onMessage(DeviceMessage msg) async {
    final rules = await _ruleRepo.getEnabledRules();
    if (rules.isEmpty) return;

    for (final reading in msg.readings) {
      for (final rule in rules) {
        // Check device filter
        if (rule.deviceAidFilter != null &&
            rule.deviceAidFilter != msg.deviceAid) {
          continue;
        }
        // Check sensor filter
        if (rule.sensorIdFilter != null &&
            rule.sensorIdFilter!.isNotEmpty &&
            rule.sensorIdFilter != reading.sensorId) {
          continue;
        }
        // Evaluate condition
        if (!rule.evaluate(reading.value)) continue;

        // Check cooldown
        final now = DateTime.now();
        final lastTrigger = _lastTriggered[rule.id];
        if (lastTrigger != null &&
            now.difference(lastTrigger).inMilliseconds < rule.cooldownMs) {
          continue;
        }

        _lastTriggered[rule.id ?? 0] = now;

        // Execute action
        await _executeAction(rule, msg, reading);
      }
    }
  }

  Future<void> _executeAction(
    Rule rule,
    DeviceMessage msg,
    dynamic reading,
  ) async {
    final sensorId = reading.sensorId as String;
    final sensorValue = reading.value as double;
    final unit = reading.unit as String;

    switch (rule.actionType) {
      case 'create_alert':
        final alertLevel = sensorValue > rule.threshold * 1.5 ? 2 : 1;
        await _alertRepo.insert(
          Alert(
            deviceAid: msg.deviceAid,
            sensorId: sensorId,
            level: alertLevel,
            message:
                'Rule "${rule.name}": $sensorId=$sensorValue $unit ${rule.operator} ${rule.threshold}',
            createdMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        break;

      case 'send_command':
        try {
          final payload =
              jsonDecode(rule.actionPayload) as Map<String, dynamic>;
          final targetAid =
              (payload['target_aid'] as num?)?.toInt() ?? msg.deviceAid;
          final cmdSensorId = (payload['sensor_id'] as String?) ?? 'CMD';
          final cmdValue = (payload['value'] as num?)?.toDouble() ?? 0.0;
          final cmdUnit = (payload['unit'] as String?) ?? '';
          final tsSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          final frame = PacketBuilder.buildSensorPacket(
            aid: targetAid,
            tid: 1,
            tsSec: tsSec,
            sensorId: cmdSensorId,
            unit: cmdUnit,
            value: cmdValue,
          );

          if (frame != null) {
            await _transport.sendCommand(frame: frame, deviceAid: targetAid);
          }
        } catch (_) {}
        break;

      case 'log_only':
      default:
        break;
    }

    // Always log triggered rule
    await _logRepo.log(
      'rule_triggered',
      details:
          'Rule "${rule.name}" triggered: device=${msg.deviceAid} $sensorId=$sensorValue ${rule.operator} ${rule.threshold} → ${rule.actionType}',
    );
  }

  void dispose() {
    stop();
  }
}
