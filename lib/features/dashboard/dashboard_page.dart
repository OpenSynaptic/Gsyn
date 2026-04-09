/// Main dashboard page — KPI cards + charts + gauges.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/core/l10n/locale_provider.dart';
import 'package:opensynaptic_dashboard/core/utils/responsive.dart';
import 'package:opensynaptic_dashboard/protocol/transport/transport_manager.dart';
import 'package:opensynaptic_dashboard/protocol/models/device_message.dart';
import 'package:opensynaptic_dashboard/protocol/models/sensor_reading.dart';
import 'package:opensynaptic_dashboard/data/repositories/repositories.dart';
import 'package:opensynaptic_dashboard/data/models/models.dart';
import 'package:opensynaptic_dashboard/widgets/kpi_card.dart';
import 'package:opensynaptic_dashboard/widgets/realtime_line_chart.dart';
import 'package:opensynaptic_dashboard/widgets/gauge_widget.dart';
import 'package:opensynaptic_dashboard/widgets/water_level_widget.dart';
import 'package:opensynaptic_dashboard/app.dart';
import 'package:opensynaptic_dashboard/widgets/bar_chart_widget.dart';
import 'package:opensynaptic_dashboard/widgets/pie_chart_widget.dart';
import 'package:opensynaptic_dashboard/features/dashboard/dashboard_config.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _deviceCount = 0;
  int _onlineCount = 0;
  int _alertCount = 0;
  int _msgPerSec = 0;

  // Live sensor data buffers (last 60 readings)
  final List<FlSpot> _tempSpots = [];
  final List<FlSpot> _humSpots = [];
  double _latestTemp = 0;
  double _latestHum = 0;
  double _latestPressure = 0;
  double _waterLevel = 0.5;
  int _spotIndex = 0;

  StreamSubscription? _msgSub;
  StreamSubscription? _statsSub;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadKpis();
    _setupStreams();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadKpis());
  }

  void _setupStreams() {
    final transport = ref.read(transportManagerProvider);
    _msgSub = transport.messageStream.listen(_onMessage);
    _statsSub = transport.statsStream.listen((stats) {
      if (mounted) setState(() => _msgPerSec = stats.messagesPerSecond);
    });
  }

  void _onMessage(DeviceMessage msg) {
    if (!mounted) return;
    // Auto-register device
    ref.read(deviceRepositoryProvider).upsertDevice(
      _deviceFromMessage(msg),
    );

    // Persist sensor data
    for (final r in msg.readings) {
      ref.read(sensorDataRepositoryProvider).insertReading(
        _sensorDataFromReading(msg.deviceAid, r, msg.timestampSec),
      );
    }

    setState(() {
      for (final r in msg.readings) {
        final sid = r.sensorId.toUpperCase();
        if (sid.contains('TEMP') || sid.contains('TMP') || sid == 'T1') {
          _latestTemp = r.value;
          _tempSpots.add(FlSpot(_spotIndex.toDouble(), r.value));
          if (_tempSpots.length > 60) _tempSpots.removeAt(0);
        } else if (sid.contains('HUM') || sid == 'H1') {
          _latestHum = r.value;
          _humSpots.add(FlSpot(_spotIndex.toDouble(), r.value));
          if (_humSpots.length > 60) _humSpots.removeAt(0);
        } else if (sid.contains('PRES') || sid.contains('BAR') || sid == 'P1') {
          _latestPressure = r.value;
        } else if (sid.contains('LEVEL') || sid.contains('LVL') || sid == 'L1') {
          _waterLevel = (r.value / 100.0).clamp(0.0, 1.0);
        }
      }
      _spotIndex++;
    });
  }

  Future<void> _loadKpis() async {
    final devRepo = ref.read(deviceRepositoryProvider);
    final alertRepo = ref.read(alertRepositoryProvider);
    final total = await devRepo.getTotalCount();
    final online = await devRepo.getOnlineCount();
    final alerts = await alertRepo.getUnacknowledgedCount();
    if (mounted) {
      setState(() {
        _deviceCount = total;
        _onlineCount = online;
        _alertCount = alerts;
      });
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _statsSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onlineRate = _deviceCount > 0 ? (_onlineCount / _deviceCount * 100) : 0.0;
    final onlineColor = onlineRate >= 90
        ? AppColors.online
        : onlineRate >= 70
            ? AppColors.warning
            : AppColors.danger;
    final cfg = ref.watch(dashboardConfigProvider);
    final l   = ref.watch(appStringsProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.dashboardTitle),
        automaticallyImplyLeading: false,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => AppShell.scaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadKpis),
        ],
      ),
      body: isDesktop
          ? _buildDesktopBody(context, cfg, l, onlineRate, onlineColor)
          : _buildMobileBody(context, cfg, l, onlineRate, onlineColor),
    );
  }

  // ── Desktop layout ──────────────────────────────────────────────────────────
  Widget _buildDesktopBody(BuildContext context, DashboardCardConfig cfg,
      AppStrings l, double onlineRate, Color onlineColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // ── KPI row: 4 compact cards side by side ─────────────────────────────
        if (cfg.kpiDevices || cfg.kpiOnlineRate || cfg.kpiAlerts || cfg.kpiThroughput)
          _desktopKpiRow(cfg, l, onlineRate, onlineColor),

        const SizedBox(height: 14),

        // ── Line charts: temp + humidity side by side ─────────────────────────
        if (cfg.chartTemp || cfg.chartHumidity)
          SizedBox(
            height: 240,
            child: Row(children: [
              if (cfg.chartTemp) Expanded(child: RealtimeLineChart(
                title: l.chartTempTrend, spots: _tempSpots,
                warningThreshold: Thresholds.tempWarning,
                dangerThreshold: Thresholds.tempDanger,
                unit: '°C', lineColor: AppColors.chartPalette[3],
              )),
              if (cfg.chartTemp && cfg.chartHumidity) const SizedBox(width: 8),
              if (cfg.chartHumidity) Expanded(child: RealtimeLineChart(
                title: l.chartHumTrend, spots: _humSpots,
                warningThreshold: Thresholds.humidityWarning,
                dangerThreshold: Thresholds.humidityDanger,
                unit: '%', lineColor: AppColors.chartPalette[0],
              )),
            ]),
          ),

        const SizedBox(height: 14),

        // ── Gauges: all 4 in one row on desktop ───────────────────────────────
        if (cfg.gaugesRow1 || cfg.gaugesRow2)
          SizedBox(
            height: 210,
            child: Row(children: [
              if (cfg.gaugesRow1) ...[
                Expanded(child: GaugeWidget(
                  title: l.gaugeTemp, value: _latestTemp,
                  min: -20, max: 80, unit: '°C',
                  warningValue: Thresholds.tempWarning,
                  dangerValue: Thresholds.tempDanger,
                )),
                const SizedBox(width: 8),
                Expanded(child: GaugeWidget(
                  title: l.gaugePressure, value: _latestPressure,
                  min: 900, max: 1200, unit: 'hPa',
                  warningValue: Thresholds.pressureWarning,
                  dangerValue: Thresholds.pressureDanger,
                )),
              ],
              if (cfg.gaugesRow1 && cfg.gaugesRow2) const SizedBox(width: 8),
              if (cfg.gaugesRow2) ...[
                Expanded(child: WaterLevelWidget(
                  title: l.gaugeLiquidLevel,
                  percentage: _waterLevel,
                  label: l.gaugeTankA,
                )),
                const SizedBox(width: 8),
                Expanded(child: GaugeWidget(
                  title: l.gaugeHumidity, value: _latestHum,
                  min: 0, max: 100, unit: '%',
                  warningValue: Thresholds.humidityWarning,
                  dangerValue: Thresholds.humidityDanger,
                )),
              ],
            ]),
          ),

        const SizedBox(height: 14),

        // ── Bar chart (60%) + Pie chart (40%) side by side ────────────────────
        if (cfg.barChart || cfg.pieChart)
          SizedBox(
            height: 240,
            child: Row(children: [
              if (cfg.barChart) Expanded(flex: 3, child: BarChartWidget(
                title: l.chartDeviceComp,
                labels: const ['Dev 1', 'Dev 2', 'Dev 3', 'Dev 4'],
                values: [_latestTemp, _latestHum, _latestPressure / 10, _waterLevel * 100],
              )),
              if (cfg.barChart && cfg.pieChart) const SizedBox(width: 8),
              if (cfg.pieChart) Expanded(flex: 2, child: PieChartWidget(
                title: l.chartDeviceTypes,
                data: {
                  l.dtSensors: 60, l.dtActuators: 20,
                  l.dtGateways: 15, l.dtOther: 5,
                },
              )),
            ]),
          ),
      ]),
    );
  }

  /// Compact horizontal KPI row for desktop.
  Widget _desktopKpiRow(DashboardCardConfig cfg, AppStrings l,
      double onlineRate, Color onlineColor) {
    final cards = <Widget>[
      if (cfg.kpiDevices) KpiCard(
        title: l.kpiTotalDevices, value: '$_deviceCount',
        icon: Icons.devices_other, color: AppColors.primary,
      ),
      if (cfg.kpiOnlineRate) KpiCard(
        title: l.kpiOnlineRate,
        value: '${onlineRate.toStringAsFixed(1)}%',
        subtitle: '$_onlineCount / $_deviceCount',
        icon: Icons.wifi, color: onlineColor,
      ),
      if (cfg.kpiAlerts) KpiCard(
        title: l.kpiActiveAlerts, value: '$_alertCount',
        icon: Icons.warning_amber_rounded,
        color: _alertCount > 0 ? AppColors.danger : AppColors.online,
      ),
      if (cfg.kpiThroughput) KpiCard(
        title: l.kpiThroughput, value: '$_msgPerSec msg/s',
        icon: Icons.speed, color: AppColors.info,
      ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    // IntrinsicHeight makes all cards the same height as the tallest one
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }

  // ── Mobile layout (unchanged) ───────────────────────────────────────────────
  Widget _buildMobileBody(BuildContext context, DashboardCardConfig cfg,
      AppStrings l, double onlineRate, Color onlineColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        // KPI Cards 2-column grid
        if (cfg.kpiDevices || cfg.kpiOnlineRate || cfg.kpiAlerts || cfg.kpiThroughput)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              if (cfg.kpiDevices)
                KpiCard(title: l.kpiTotalDevices, value: '$_deviceCount',
                    icon: Icons.devices_other, color: AppColors.primary),
              if (cfg.kpiOnlineRate)
                KpiCard(title: l.kpiOnlineRate,
                    value: '${onlineRate.toStringAsFixed(1)}%',
                    subtitle: '$_onlineCount / $_deviceCount',
                    icon: Icons.wifi, color: onlineColor),
              if (cfg.kpiAlerts)
                KpiCard(title: l.kpiActiveAlerts, value: '$_alertCount',
                    icon: Icons.warning_amber_rounded,
                    color: _alertCount > 0 ? AppColors.danger : AppColors.online),
              if (cfg.kpiThroughput)
                KpiCard(title: l.kpiThroughput, value: '$_msgPerSec msg/s',
                    icon: Icons.speed, color: AppColors.info),
            ],
          ),

        if (cfg.chartTemp)
          SizedBox(height: 220, child: RealtimeLineChart(
            title: l.chartTempTrend, spots: _tempSpots,
            warningThreshold: Thresholds.tempWarning,
            dangerThreshold: Thresholds.tempDanger,
            unit: '°C', lineColor: AppColors.chartPalette[3],
          )),
        if (cfg.chartHumidity)
          SizedBox(height: 220, child: RealtimeLineChart(
            title: l.chartHumTrend, spots: _humSpots,
            warningThreshold: Thresholds.humidityWarning,
            dangerThreshold: Thresholds.humidityDanger,
            unit: '%', lineColor: AppColors.chartPalette[0],
          )),

        if (cfg.gaugesRow1)
          SizedBox(height: 200, child: Row(children: [
            Expanded(child: GaugeWidget(
              title: l.gaugeTemp, value: _latestTemp,
              min: -20, max: 80, unit: '°C',
              warningValue: Thresholds.tempWarning, dangerValue: Thresholds.tempDanger,
            )),
            Expanded(child: GaugeWidget(
              title: l.gaugePressure, value: _latestPressure,
              min: 900, max: 1200, unit: 'hPa',
              warningValue: Thresholds.pressureWarning, dangerValue: Thresholds.pressureDanger,
            )),
          ])),

        if (cfg.gaugesRow2)
          SizedBox(height: 200, child: Row(children: [
            Expanded(child: WaterLevelWidget(
              title: l.gaugeLiquidLevel, percentage: _waterLevel, label: l.gaugeTankA,
            )),
            Expanded(child: GaugeWidget(
              title: l.gaugeHumidity, value: _latestHum,
              min: 0, max: 100, unit: '%',
              warningValue: Thresholds.humidityWarning, dangerValue: Thresholds.humidityDanger,
            )),
          ])),

        if (cfg.barChart)
          SizedBox(height: 220, child: BarChartWidget(
            title: l.chartDeviceComp,
            labels: const ['Dev 1', 'Dev 2', 'Dev 3', 'Dev 4'],
            values: [_latestTemp, _latestHum, _latestPressure / 10, _waterLevel * 100],
          )),
        if (cfg.pieChart)
          SizedBox(height: 220, child: PieChartWidget(
            title: l.chartDeviceTypes,
            data: {
              l.dtSensors: 60, l.dtActuators: 20,
              l.dtGateways: 15, l.dtOther: 5,
            },
          )),
      ]),
    );
  }
} // end _DashboardPageState

// Helper conversions

Device _deviceFromMessage(DeviceMessage msg) => Device(
      aid: msg.deviceAid,
      name: msg.nodeId.isNotEmpty ? msg.nodeId : 'Device ${msg.deviceAid}',
      status: 'online',
      transportType: msg.transportType,
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
    );

SensorData _sensorDataFromReading(int aid, SensorReading r, int tsSec) => SensorData(
      deviceAid: aid,
      sensorId: r.sensorId,
      unit: r.unit,
      value: r.value,
      rawB62: r.rawB62,
      timestampMs: tsSec * 1000,
    );

