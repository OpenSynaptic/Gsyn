/// Send page — full OpenSynaptic CMD command palette with per-command params.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/app.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/core/protocol_constants.dart';
import 'package:opensynaptic_dashboard/data/models/models.dart';
import 'package:opensynaptic_dashboard/data/repositories/repositories.dart';
import 'package:opensynaptic_dashboard/protocol/codec/commands.dart';
import 'package:opensynaptic_dashboard/protocol/codec/packet_builder.dart';
import 'package:opensynaptic_dashboard/protocol/transport/transport_manager.dart';

// ── Send log entry ────────────────────────────────────────────────────────────
class _LogEntry {
  final DateTime time;
  final String cmdName;
  final bool success;
  final String detail;
  _LogEntry(this.time, this.cmdName, this.success, this.detail);
}

// ── Page ──────────────────────────────────────────────────────────────────────
class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});
  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  List<Device> _devices = [];
  int? _selectedAid;

  // common param controllers
  final _aidCtrl      = TextEditingController(text: '1');
  final _tidCtrl      = TextEditingController(text: '1');
  final _seqCtrl      = TextEditingController(text: '0');
  final _targetIpCtrl = TextEditingController(text: '192.168.1.100');
  final _targetPortCtrl = TextEditingController(text: '9876');

  // sensor data — use dropdowns
  String _selectedSensorId = 'TEMP';
  String _selectedUnit     = '°C';
  String _selectedState    = 'U';
  final _valueCtrl     = TextEditingController(text: '25.0');

  // multi-sensor rows: each row stores sid/unit/value/state as Strings+controller
  final List<_SensorRow> _multiSensors = [];

  // id_assign
  final _assignAidCtrl = TextEditingController(text: '1');

  // raw hex
  final _rawHexCtrl = TextEditingController();

  final List<_LogEntry> _log = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadDevices();
    _addMultiSensorRow();
  }

  @override
  void dispose() {
    _tab.dispose();
    _aidCtrl.dispose(); _tidCtrl.dispose(); _seqCtrl.dispose();
    _targetIpCtrl.dispose(); _targetPortCtrl.dispose();
    _valueCtrl.dispose();
    _assignAidCtrl.dispose(); _rawHexCtrl.dispose();
    for (final row in _multiSensors) {
      row.valueCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final d = await ref.read(deviceRepositoryProvider).getAllDevices();
    if (mounted) setState(() => _devices = d);
  }

  void _addMultiSensorRow() {
    _multiSensors.add(_SensorRow(
      sid:   kOsSensorIds[_multiSensors.length % kOsSensorIds.length],
      unit:  '°C',
      state: 'U',
      valueCtrl: TextEditingController(text: '0.0'),
    ));
    if (mounted) setState(() {});
  }

  // ── Send helpers ────────────────────────────────────────────────────────────
  int get _aid  => int.tryParse(_aidCtrl.text)  ?? 1;
  int get _tid  => int.tryParse(_tidCtrl.text)  ?? 1;
  int get _seq  => int.tryParse(_seqCtrl.text)  ?? 0;
  int get _tsSec => DateTime.now().millisecondsSinceEpoch ~/ 1000;
  String get _ip   => _targetIpCtrl.text.trim();
  int    get _port => int.tryParse(_targetPortCtrl.text) ?? 9876;

  Future<void> _send(String name, Uint8List frame) async {
    final tm = ref.read(transportManagerProvider);
    bool ok;
    try {
      ok = await tm.sendCommand(
          frame: frame, deviceAid: _aid, udpHost: _ip, udpPort: _port);
    } catch (e) {
      ok = false;
    }
    // log operation
    ref.read(operationLogRepositoryProvider).log(
      'SEND_CMD',
      details: '$name → AID:$_aid target:$_ip:$_port ok=$ok',
    );
    setState(() {
      _log.insert(0, _LogEntry(DateTime.now(), name, ok,
          ok ? '→ $_ip:$_port (${frame.length} bytes)' : '发送失败'));
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: ok ? AppColors.online : AppColors.danger,
        content: Text(ok ? '$name 发送成功' : '$name 发送失败'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _sendPing()        => _send('PING',         PacketBuilder.buildPing(_seq));
  void _sendPong()        => _send('PONG',         PacketBuilder.buildPong(_seq));
  void _sendIdRequest()   => _send('ID_REQUEST',   PacketBuilder.buildIdRequest(_seq));
  void _sendTimeRequest() => _send('TIME_REQUEST', PacketBuilder.buildTimeRequest(_seq));

  void _sendHandshakeAck() {
    final frame = Uint8List(1)..[0] = OsCmd.handshakeAck;
    _send('HANDSHAKE_ACK', frame);
  }
  void _sendHandshakeNack() {
    final frame = Uint8List(1)..[0] = OsCmd.handshakeNack;
    _send('HANDSHAKE_NACK', frame);
  }
  void _sendIdAssign() {
    final assignAid = int.tryParse(_assignAidCtrl.text) ?? 1;
    final frame = Uint8List(5);
    frame[0] = OsCmd.idAssign;
    frame[1] = (assignAid >> 24) & 0xFF;
    frame[2] = (assignAid >> 16) & 0xFF;
    frame[3] = (assignAid >> 8) & 0xFF;
    frame[4] = assignAid & 0xFF;
    _send('ID_ASSIGN', frame);
  }
  void _sendSecureDictReady() {
    final frame = Uint8List(1)..[0] = OsCmd.secureDictReady;
    _send('SECURE_DICT_READY', frame);
  }

  void _sendSensorData() {
    final f = PacketBuilder.buildSensorPacket(
      aid:      _aid,
      tid:      _tid,
      tsSec:    _tsSec,
      sensorId: _selectedSensorId,
      unit:     _selectedUnit,
      value:    double.tryParse(_valueCtrl.text) ?? 0.0,
    );
    if (f != null) _send('DATA_FULL (sensor)', f);
  }

  void _sendMultiSensorData() {
    final sensors = _multiSensors.map((row) => {
          'sensor_id': row.sid,
          'unit':      row.unit,
          'value':     double.tryParse(row.valueCtrl.text) ?? 0.0,
          'state':     row.state,
        }).toList();
    final f = PacketBuilder.buildMultiSensorPacket(
      aid:       _aid, tid: _tid, tsSec: _tsSec,
      nodeId:    _aidCtrl.text, nodeState: 'U',
      sensors:   sensors,
    );
    if (f != null) _send('DATA_FULL (multi-sensor)', f);
  }

  void _sendRawHex() {
    final hex = _rawHexCtrl.text.replaceAll(RegExp(r'\s'), '');
    if (hex.isEmpty || hex.length % 2 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无效 HEX 字符串（长度必须为偶数）')));
      return;
    }
    try {
      final bytes = Uint8List(hex.length ~/ 2);
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      }
      _send('RAW', bytes);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('HEX 解析失败')));
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Commands'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.scaffoldKey.currentState?.openDrawer(),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.settings_remote, size: 18), text: '控制'),
            Tab(icon: Icon(Icons.sensors,          size: 18), text: '数据'),
            Tab(icon: Icon(Icons.code,             size: 18), text: '原始'),
          ],
        ),
      ),
      body: Column(children: [
        // ── Target config bar ─────────────────────────────────────────────────
        _TargetBar(
          devices: _devices,
          selectedAid: _selectedAid,
          aidCtrl: _aidCtrl,
          tidCtrl: _tidCtrl,
          seqCtrl: _seqCtrl,
          ipCtrl:  _targetIpCtrl,
          portCtrl: _targetPortCtrl,
          onDeviceSelected: (aid) => setState(() {
            _selectedAid = aid;
            _aidCtrl.text = aid.toString();
          }),
        ),
        const Divider(height: 1),

        // ── Command tabs ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _ControlTab(
                seqCtrl:        _seqCtrl,
                assignAidCtrl:  _assignAidCtrl,
                onPing:               _sendPing,
                onPong:               _sendPong,
                onIdRequest:          _sendIdRequest,
                onIdAssign:           _sendIdAssign,
                onTimeRequest:        _sendTimeRequest,
                onHandshakeAck:       _sendHandshakeAck,
                onHandshakeNack:      _sendHandshakeNack,
                onSecureDictReady:    _sendSecureDictReady,
                log: _log,
              ),
              _DataTab(
                selectedSensorId: _selectedSensorId,
                selectedUnit:     _selectedUnit,
                selectedState:    _selectedState,
                valueCtrl:        _valueCtrl,
                multiSensors:     _multiSensors,
                onAddRow:         _addMultiSensorRow,
                onSendSingle:     _sendSensorData,
                onSendMulti:      _sendMultiSensorData,
                onSensorChanged:  (v) => setState(() {
                  _selectedSensorId = v;
                  _selectedUnit = kOsSensorDefaultUnit[v] ?? _selectedUnit;
                }),
                onUnitChanged:    (v) => setState(() => _selectedUnit = v),
                onStateChanged:   (v) => setState(() => _selectedState = v),
                onRowChanged:     () => setState(() {}),
                log: _log,
              ),
              _RawTab(
                hexCtrl: _rawHexCtrl,
                onSend:  _sendRawHex,
                log: _log,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Target config bar ─────────────────────────────────────────────────────────
class _TargetBar extends StatelessWidget {
  final List<Device> devices;
  final int? selectedAid;
  final TextEditingController aidCtrl, tidCtrl, seqCtrl, ipCtrl, portCtrl;
  final ValueChanged<int> onDeviceSelected;

  const _TargetBar({
    required this.devices, required this.selectedAid,
    required this.aidCtrl, required this.tidCtrl, required this.seqCtrl,
    required this.ipCtrl, required this.portCtrl,
    required this.onDeviceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: devices.isEmpty
                ? TextField(
                    controller: aidCtrl,
                    decoration: const InputDecoration(
                        labelText: '目标 AID', isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                    keyboardType: TextInputType.number,
                  )
                : DropdownButtonFormField<int>(
                    initialValue: selectedAid,
                    decoration: const InputDecoration(
                        labelText: '目标设备', isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                    hint: const Text('选择已知设备'),
                    items: devices.map((d) => DropdownMenuItem(
                      value: d.aid,
                      child: Text('${d.name.isNotEmpty ? d.name : 'Device'} (AID: ${d.aid})',
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) { if (v != null) onDeviceSelected(v); },
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: TextField(
              controller: tidCtrl,
              decoration: const InputDecoration(
                  labelText: 'TID', isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
              keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: TextField(
              controller: seqCtrl,
              decoration: const InputDecoration(
                  labelText: 'SEQ', isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
              keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.send_to_mobile, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: TextField(
              controller: ipCtrl,
              decoration: const InputDecoration(
                  labelText: '目标 IP', isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)))),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: TextField(
              controller: portCtrl,
              decoration: const InputDecoration(
                  labelText: '端口', isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
              keyboardType: TextInputType.number)),
        ]),
      ]),
    );
  }
}

// ── Control commands tab ──────────────────────────────────────────────────────
class _ControlTab extends StatelessWidget {
  final TextEditingController seqCtrl, assignAidCtrl;
  final VoidCallback onPing, onPong, onIdRequest, onIdAssign,
      onTimeRequest, onHandshakeAck, onHandshakeNack, onSecureDictReady;
  final List<_LogEntry> log;

  const _ControlTab({
    required this.seqCtrl, required this.assignAidCtrl,
    required this.onPing, required this.onPong, required this.onIdRequest,
    required this.onIdAssign, required this.onTimeRequest,
    required this.onHandshakeAck, required this.onHandshakeNack,
    required this.onSecureDictReady, required this.log,
  });

  Widget _cmd(BuildContext ctx, String name, int byte, String desc,
      VoidCallback action, {Widget? extra}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _CmdBadge('0x${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
                color: AppColors.info),
            const SizedBox(width: 8),
            Expanded(child: Text(name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            FilledButton.tonal(
              onPressed: action,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(60, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
              child: const Text('发送'),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(desc,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
          if (extra != null) ...[const SizedBox(height: 4), extra],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(bottom: 8), children: [
      const _CmdGroupHeader('连接握手'),
      _cmd(context, 'PING',          OsCmd.ping,          '发送心跳探测，对端应回复 PONG', onPing),
      _cmd(context, 'PONG',          OsCmd.pong,          '回复 PING 的响应帧', onPong),
      _cmd(context, 'HANDSHAKE_ACK', OsCmd.handshakeAck,  '确认握手成功', onHandshakeAck),
      _cmd(context, 'HANDSHAKE_NACK', OsCmd.handshakeNack,'拒绝握手', onHandshakeNack),

      const _CmdGroupHeader('ID 管理'),
      _cmd(context, 'ID_REQUEST', OsCmd.idRequest, '请求服务器分配 AID', onIdRequest),
      _cmd(context, 'ID_ASSIGN',  OsCmd.idAssign,  '向设备分配指定 AID',  onIdAssign,
          extra: TextField(
            controller: assignAidCtrl,
            decoration: const InputDecoration(
                labelText: '分配的 AID', isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            keyboardType: TextInputType.number,
          )),

      const _CmdGroupHeader('时间同步'),
      _cmd(context, 'TIME_REQUEST', OsCmd.timeRequest, '请求服务器时间戳', onTimeRequest),

      const _CmdGroupHeader('安全信道'),
      _cmd(context, 'SECURE_DICT_READY', OsCmd.secureDictReady, '通知安全字典已就绪', onSecureDictReady),

      const SizedBox(height: 12),
      _LogPanel(log),
    ]);
  }
}

// ── Data commands tab ─────────────────────────────────────────────────────────
class _DataTab extends StatelessWidget {
  final String selectedSensorId;
  final String selectedUnit;
  final String selectedState;
  final TextEditingController valueCtrl;
  final List<_SensorRow> multiSensors;
  final VoidCallback onAddRow, onSendSingle, onSendMulti;
  final ValueChanged<String> onSensorChanged, onUnitChanged, onStateChanged;
  final VoidCallback onRowChanged;
  final List<_LogEntry> log;

  const _DataTab({
    required this.selectedSensorId, required this.selectedUnit,
    required this.selectedState,    required this.valueCtrl,
    required this.multiSensors,     required this.onAddRow,
    required this.onSendSingle,     required this.onSendMulti,
    required this.onSensorChanged,  required this.onUnitChanged,
    required this.onStateChanged,   required this.onRowChanged,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      // ── Single sensor ─────────────────────────────────────────────────────
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CmdBadge('0x${OsCmd.dataFull.toRadixString(16).toUpperCase()}',
              color: AppColors.primary),
          const SizedBox(height: 2),
          const Text('DATA_FULL — 单传感器',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          // Sensor ID dropdown
          Row(children: [
            Expanded(child: _OsDropdown<String>(
              label: '传感器 ID',
              value: selectedSensorId,
              items: kOsSensorIds,
              onChanged: onSensorChanged,
            )),
            const SizedBox(width: 8),
            // State dropdown
            SizedBox(width: 80, child: _OsDropdown<String>(
              label: '状态',
              value: selectedState,
              items: kOsStates,
              onChanged: onStateChanged,
            )),
          ]),
          const SizedBox(height: 8),

          // Unit dropdown + value
          Row(children: [
            Expanded(child: _OsDropdown<String>(
              label: '单位 (unit)',
              value: selectedUnit,
              items: kOsUnits,
              onChanged: onUnitChanged,
            )),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: valueCtrl,
              decoration: const InputDecoration(labelText: '数值', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            )),
          ]),
          const SizedBox(height: 4),
          Text(
            '格式预览: $selectedSensorId>$selectedState.$selectedUnit:{b62}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary,
                fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight,
              child: FilledButton.tonal(onPressed: onSendSingle,
                  child: const Text('发送单传感器'))),
        ],
      ))),

      const SizedBox(height: 8),

      // ── Multi sensor ──────────────────────────────────────────────────────
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CmdBadge('0x${OsCmd.dataFull.toRadixString(16).toUpperCase()}',
              color: AppColors.online),
          const SizedBox(height: 2),
          Row(children: [
            const Expanded(child: Text('DATA_FULL — 多传感器',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: onAddRow, tooltip: '添加传感器行'),
          ]),
          const SizedBox(height: 4),
          ...multiSensors.asMap().entries.map((e) {
            final row = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text('${e.key + 1}.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                Expanded(child: _OsDropdown<String>(
                  label: 'SID', value: row.sid,
                  items: kOsSensorIds,
                  onChanged: (v) {
                    row.sid = v;
                    row.unit = kOsSensorDefaultUnit[v] ?? row.unit;
                    onRowChanged();
                  },
                )),
                const SizedBox(width: 4),
                SizedBox(width: 80, child: _OsDropdown<String>(
                  label: '单位', value: row.unit,
                  items: kOsUnits,
                  onChanged: (v) { row.unit = v; onRowChanged(); },
                )),
                const SizedBox(width: 4),
                SizedBox(width: 70, child: TextField(
                  controller: row.valueCtrl,
                  decoration: const InputDecoration(labelText: '数值', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                )),
                const SizedBox(width: 4),
                SizedBox(width: 52, child: _OsDropdown<String>(
                  label: '状态', value: row.state,
                  items: kOsStates,
                  onChanged: (v) { row.state = v; onRowChanged(); },
                )),
              ]),
            );
          }),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight,
              child: FilledButton.tonal(onPressed: onSendMulti,
                  child: const Text('发送多传感器'))),
        ],
      ))),

      const SizedBox(height: 12),
      _LogPanel(log),
    ]);
  }
}

// ── Raw hex tab ───────────────────────────────────────────────────────────────
class _RawTab extends StatelessWidget {
  final TextEditingController hexCtrl;
  final VoidCallback onSend;
  final List<_LogEntry> log;
  const _RawTab({required this.hexCtrl, required this.onSend, required this.log});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('原始 HEX 帧',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('输入不含空格或带空格的十六进制字节串，例如：0901 02 03',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: hexCtrl,
            maxLines: 3,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F\s]')),
            ],
            decoration: const InputDecoration(
                labelText: 'HEX 字节串',
                hintText: '09 00 01'),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton.icon(
                onPressed: () => hexCtrl.clear(),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('清空')),
            FilledButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('发送原始帧')),
          ]),
        ],
      ))),

      // Command reference table
      const SizedBox(height: 8),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CMD 字节速查表',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._cmdRef.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              SizedBox(width: 48, child: Text(
                  '0x${r[0].toRadixString(16).toUpperCase().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace',
                      color: AppColors.info))),
              Expanded(child: Text(r[1] as String,
                  style: const TextStyle(fontSize: 12))),
            ]),
          )),
        ],
      ))),

      const SizedBox(height: 12),
      _LogPanel(log),
    ]);
  }

  static final List<List<dynamic>> _cmdRef = [
    [OsCmd.ping,             'PING'],
    [OsCmd.pong,             'PONG'],
    [OsCmd.idRequest,        'ID_REQUEST'],
    [OsCmd.idAssign,         'ID_ASSIGN'],
    [OsCmd.idPoolReq,        'ID_POOL_REQ'],
    [OsCmd.idPoolRes,        'ID_POOL_RES'],
    [OsCmd.handshakeAck,     'HANDSHAKE_ACK'],
    [OsCmd.handshakeNack,    'HANDSHAKE_NACK'],
    [OsCmd.timeRequest,      'TIME_REQUEST'],
    [OsCmd.timeResponse,     'TIME_RESPONSE'],
    [OsCmd.secureDictReady,  'SECURE_DICT_READY'],
    [OsCmd.secureChannelAck, 'SECURE_CHANNEL_ACK'],
    [OsCmd.dataFull,         'DATA_FULL'],
    [OsCmd.dataFullSec,      'DATA_FULL_SEC'],
    [OsCmd.dataDiff,         'DATA_DIFF'],
    [OsCmd.dataDiffSec,      'DATA_DIFF_SEC'],
    [OsCmd.dataHeart,        'DATA_HEART'],
    [OsCmd.dataHeartSec,     'DATA_HEART_SEC'],
  ];
}

// ── Mutable sensor row for multi-sensor packets ───────────────────────────────
class _SensorRow {
  String sid;
  String unit;
  String state;
  final TextEditingController valueCtrl;
  _SensorRow({required this.sid, required this.unit,
      required this.state, required this.valueCtrl});
}

// ── OpenSynaptic-constrained dropdown ─────────────────────────────────────────
class _OsDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  const _OsDropdown({required this.label, required this.value,
      required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    isDense: true,
    isExpanded: true,
    initialValue: value,
    decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
    items: items.map((i) => DropdownMenuItem<T>(
        value: i, child: Text(i.toString(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13)))).toList(),
    onChanged: (v) { if (v != null) onChanged(v); },
  );
}

// ── CMD badge ─────────────────────────────────────────────────────────────────
class _CmdBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _CmdBadge(this.text, {required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4)),
    child: Text(text,
        style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: color)),
  );
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _CmdGroupHeader extends StatelessWidget {
  final String title;
  const _CmdGroupHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8)),
      );
}

class _LogPanel extends StatelessWidget {
  final List<_LogEntry> log;
  const _LogPanel(this.log);
  @override
  Widget build(BuildContext context) {
    if (log.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('发送日志',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...log.take(20).map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Icon(e.success ? Icons.check_circle : Icons.error,
                    size: 14,
                    color: e.success ? AppColors.online : AppColors.danger),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  '${_hms(e.time)}  ${e.cmdName}  ${e.detail}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  static String _hms(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';
}

