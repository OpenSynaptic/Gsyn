"""Generate remaining Dart source files for the OpenSynaptic Dashboard app."""
import os

BASE = r"C:\Users\MaoJu\AndroidStudioProjects\opensynaptic_dashboard\lib"

files = {}

# ─── Devices page (fix) ───
files["features/devices/devices_page.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/data/models/models.dart';
import 'package:opensynaptic_dashboard/data/repositories/repositories.dart';

class DeviceListPage extends ConsumerStatefulWidget {
  const DeviceListPage({super.key});
  @override
  ConsumerState<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends ConsumerState<DeviceListPage> {
  List<Device> _devices = [];
  String _search = '';
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final d = await ref.read(deviceRepositoryProvider).getAllDevices();
    if (mounted) setState(() => _devices = d);
  }
  @override
  Widget build(BuildContext context) {
    final list = _devices.where((d) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return d.name.toLowerCase().contains(q) || d.aid.toString().contains(q);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: TextField(
          decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search, size: 20), isDense: true),
          onChanged: (v) => setState(() => _search = v),
        )),
        Expanded(child: RefreshIndicator(onRefresh: _load, child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final d = list[i]; final on = d.status == 'online';
            return Card(child: ListTile(
              leading: Icon(Icons.devices_other, color: on ? AppColors.online : AppColors.offline),
              title: Text(d.name.isNotEmpty ? d.name : 'Device ${d.aid}'),
              subtitle: Text('AID: ${d.aid}', style: const TextStyle(fontSize: 12)),
              trailing: Text(d.status.toUpperCase(), style: TextStyle(fontSize: 11, color: on ? AppColors.online : AppColors.offline)),
              onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => DeviceDetailPage(device: d))),
            ));
          },
        ))),
      ]),
    );
  }
}

class DeviceDetailPage extends ConsumerStatefulWidget {
  final Device device;
  const DeviceDetailPage({super.key, required this.device});
  @override
  ConsumerState<DeviceDetailPage> createState() => _DeviceDetailState();
}
class _DeviceDetailState extends ConsumerState<DeviceDetailPage> {
  List<SensorData> _readings = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final r = await ref.read(sensorDataRepositoryProvider).getLatestByDevice(widget.device.aid);
    if (mounted) setState(() => _readings = r);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name.isNotEmpty ? widget.device.name : 'Device ${widget.device.aid}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('AID: ${widget.device.aid} | ${widget.device.transportType.toUpperCase()} | ${widget.device.status}'))),
        const SizedBox(height: 16),
        const Text('Latest Readings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ..._readings.map((r) => Card(child: ListTile(
          title: Text(r.sensorId),
          trailing: Text('${r.value.toStringAsFixed(2)} ${r.unit}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.network_ping), label: const Text('PING')),
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.restart_alt), label: const Text('RESET')),
          ],
        ))),
      ]),
    );
  }
}
"""

# ─── Alerts page ───
files["features/alerts/alerts_page.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/data/models/models.dart';
import 'package:opensynaptic_dashboard/data/repositories/repositories.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});
  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}
class _AlertsPageState extends ConsumerState<AlertsPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Alert> _alerts = [];
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }
  Future<void> _load() async {
    final a = await ref.read(alertRepositoryProvider).getAlerts(limit: 200);
    if (mounted) setState(() => _alerts = a);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts'), bottom: TabBar(controller: _tabCtrl, tabs: const [
        Tab(text: 'Critical'), Tab(text: 'Warning'), Tab(text: 'Info'),
      ])),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildList(2), _buildList(1), _buildList(0),
      ]),
    );
  }
  Widget _buildList(int level) {
    final filtered = _alerts.where((a) => a.level == level).toList();
    if (filtered.isEmpty) return const Center(child: Text('No alerts', style: TextStyle(color: AppColors.textSecondary)));
    return RefreshIndicator(onRefresh: _load, child: ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final a = filtered[i];
        final color = a.level == 2 ? AppColors.danger : a.level == 1 ? AppColors.warning : AppColors.info;
        return Card(child: ListTile(
          leading: Icon(a.level == 2 ? Icons.error : a.level == 1 ? Icons.warning : Icons.info, color: color),
          title: Text(a.message, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('Device: ${a.deviceAid} • ${DateTime.fromMillisecondsSinceEpoch(a.createdMs).toString().substring(0, 16)}',
              style: const TextStyle(fontSize: 11)),
          trailing: a.acknowledged ? const Icon(Icons.check_circle, color: AppColors.online, size: 20)
              : IconButton(icon: const Icon(Icons.check, size: 20), onPressed: () async {
                  await ref.read(alertRepositoryProvider).acknowledge(a.id!);
                  _load();
                }),
        ));
      },
    ));
  }
}
"""

# ─── History page ───
files["features/history/history_page.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/data/models/models.dart';
import 'package:opensynaptic_dashboard/data/repositories/repositories.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}
class _HistoryPageState extends ConsumerState<HistoryPage> {
  List<SensorData> _data = [];
  bool _loading = false;
  @override
  void initState() { super.initState(); _query(); }
  Future<void> _query() async {
    setState(() => _loading = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final from = now - 86400000; // last 24h
    final d = await ref.read(sensorDataRepositoryProvider).query(fromMs: from, toMs: now, limit: 500);
    if (mounted) setState(() { _data = d; _loading = false; });
  }
  Future<void> _export() async {
    final rows = [['Timestamp', 'Device AID', 'Sensor', 'Value', 'Unit']];
    for (final d in _data) {
      rows.add([DateTime.fromMillisecondsSinceEpoch(d.timestampMs).toIso8601String(), d.deviceAid.toString(), d.sensorId, d.value.toString(), d.unit]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History'), actions: [
        IconButton(icon: const Icon(Icons.file_download), onPressed: _export),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _query),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty ? const Center(child: Text('No data', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
        itemCount: _data.length,
        itemBuilder: (ctx, i) {
          final d = _data[i];
          return Card(child: ListTile(
            dense: true,
            title: Text('${d.sensorId}: ${d.value.toStringAsFixed(2)} ${d.unit}'),
            subtitle: Text('Device ${d.deviceAid} • ${DateTime.fromMillisecondsSinceEpoch(d.timestampMs).toString().substring(0, 19)}',
                style: const TextStyle(fontSize: 11)),
          ));
        },
      ),
    );
  }
}
"""

# ─── Map page ───
files["features/map/map_page.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/data/models/models.dart';
import 'package:opensynaptic_dashboard/data/repositories/repositories.dart';

class DeviceMapPage extends ConsumerStatefulWidget {
  const DeviceMapPage({super.key});
  @override
  ConsumerState<DeviceMapPage> createState() => _DeviceMapPageState();
}
class _DeviceMapPageState extends ConsumerState<DeviceMapPage> {
  List<Device> _devices = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final d = await ref.read(deviceRepositoryProvider).getAllDevices();
    if (mounted) setState(() => _devices = d);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Map')),
      body: FlutterMap(
        options: const MapOptions(initialCenter: LatLng(30.0, 120.0), initialZoom: 5),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
          MarkerLayer(markers: _devices.where((d) => d.lat != 0 || d.lng != 0).map((d) {
            final on = d.status == 'online';
            return Marker(
              point: LatLng(d.lat, d.lng),
              width: 40, height: 40,
              child: Icon(Icons.location_on, color: on ? AppColors.online : AppColors.offline, size: 36),
            );
          }).toList()),
        ],
      ),
    );
  }
}
"""

# ─── Rules config page ───
files["features/rules_config/rules_config_page.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/data/models/models.dart';
import 'package:opensynaptic_dashboard/data/repositories/repositories.dart';

class RulesConfigPage extends ConsumerStatefulWidget {
  const RulesConfigPage({super.key});
  @override
  ConsumerState<RulesConfigPage> createState() => _RulesConfigPageState();
}
class _RulesConfigPageState extends ConsumerState<RulesConfigPage> {
  List<Rule> _rules = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final r = await ref.read(ruleRepositoryProvider).getAllRules();
    if (mounted) setState(() => _rules = r);
  }
  void _addRule() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RuleEditPage(onSaved: _load)));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rules Engine')),
      floatingActionButton: FloatingActionButton(onPressed: _addRule, child: const Icon(Icons.add)),
      body: _rules.isEmpty ? const Center(child: Text('No rules configured', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
        itemCount: _rules.length,
        itemBuilder: (ctx, i) {
          final r = _rules[i];
          return Card(child: ListTile(
            title: Text(r.name.isNotEmpty ? r.name : 'Rule ${r.id}'),
            subtitle: Text('${r.sensorIdFilter ?? '*'} ${r.operator} ${r.threshold} → ${r.actionType}', style: const TextStyle(fontSize: 12)),
            trailing: Switch(value: r.enabled, onChanged: (v) async {
              await ref.read(ruleRepositoryProvider).toggleEnabled(r.id!, v);
              _load();
            }),
          ));
        },
      ),
    );
  }
}

class RuleEditPage extends ConsumerStatefulWidget {
  final VoidCallback? onSaved;
  const RuleEditPage({super.key, this.onSaved});
  @override
  ConsumerState<RuleEditPage> createState() => _RuleEditPageState();
}
class _RuleEditPageState extends ConsumerState<RuleEditPage> {
  final _nameCtrl = TextEditingController();
  final _sensorCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController(text: '50');
  String _operator = '>';
  String _actionType = 'create_alert';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Rule'), actions: [
        TextButton(onPressed: _save, child: const Text('SAVE')),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Rule Name')),
        const SizedBox(height: 12),
        TextField(controller: _sensorCtrl, decoration: const InputDecoration(labelText: 'Sensor ID Filter (e.g. TEMP)')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _operator, items: ['>', '<', '>=', '<=', '==', '!='].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(), onChanged: (v) => setState(() => _operator = v!))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _thresholdCtrl, decoration: const InputDecoration(labelText: 'Threshold'), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _actionType, decoration: const InputDecoration(labelText: 'Action'),
            items: const [
              DropdownMenuItem(value: 'create_alert', child: Text('Create Alert')),
              DropdownMenuItem(value: 'send_command', child: Text('Send Command')),
              DropdownMenuItem(value: 'log_only', child: Text('Log Only')),
            ], onChanged: (v) => setState(() => _actionType = v!)),
      ]),
    );
  }
  Future<void> _save() async {
    final rule = Rule(
      name: _nameCtrl.text,
      sensorIdFilter: _sensorCtrl.text.isEmpty ? null : _sensorCtrl.text,
      operator: _operator,
      threshold: double.tryParse(_thresholdCtrl.text) ?? 0,
      actionType: _actionType,
      enabled: true,
    );
    await ref.read(ruleRepositoryProvider).insert(rule);
    widget.onSaved?.call();
    if (mounted) Navigator.pop(context);
  }
}
"""

# ─── Settings page ───
files["features/settings/settings_page.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/protocol/transport/transport_manager.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _udpHostCtrl = TextEditingController(text: '0.0.0.0');
  final _udpPortCtrl = TextEditingController(text: '9876');
  final _mqttBrokerCtrl = TextEditingController(text: 'localhost');
  final _mqttPortCtrl = TextEditingController(text: '1883');
  bool _udpEnabled = true;
  bool _mqttEnabled = false;

  @override
  void initState() { super.initState(); _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _udpHostCtrl.text = prefs.getString('udp_host') ?? '0.0.0.0';
      _udpPortCtrl.text = prefs.getString('udp_port') ?? '9876';
      _mqttBrokerCtrl.text = prefs.getString('mqtt_broker') ?? 'localhost';
      _mqttPortCtrl.text = prefs.getString('mqtt_port') ?? '1883';
      _udpEnabled = prefs.getBool('udp_enabled') ?? true;
      _mqttEnabled = prefs.getBool('mqtt_enabled') ?? false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('udp_host', _udpHostCtrl.text);
    await prefs.setString('udp_port', _udpPortCtrl.text);
    await prefs.setString('mqtt_broker', _mqttBrokerCtrl.text);
    await prefs.setString('mqtt_port', _mqttPortCtrl.text);
    await prefs.setBool('udp_enabled', _udpEnabled);
    await prefs.setBool('mqtt_enabled', _mqttEnabled);

    final tm = ref.read(transportManagerProvider);
    if (_udpEnabled) {
      await tm.udp.listen(_udpHostCtrl.text, int.tryParse(_udpPortCtrl.text) ?? 9876);
    } else {
      await tm.udp.stop();
    }
    if (_mqttEnabled) {
      await tm.mqtt.connect(broker: _mqttBrokerCtrl.text, port: int.tryParse(_mqttPortCtrl.text) ?? 1883);
    } else {
      await tm.mqtt.disconnect();
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), actions: [TextButton(onPressed: _save, child: const Text('SAVE'))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('UDP Transport', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SwitchListTile(title: const Text('Enable UDP'), value: _udpEnabled, onChanged: (v) => setState(() => _udpEnabled = v)),
        TextField(controller: _udpHostCtrl, decoration: const InputDecoration(labelText: 'Listen Host')),
        const SizedBox(height: 8),
        TextField(controller: _udpPortCtrl, decoration: const InputDecoration(labelText: 'Listen Port'), keyboardType: TextInputType.number),
        const SizedBox(height: 24),
        const Text('MQTT Transport', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SwitchListTile(title: const Text('Enable MQTT'), value: _mqttEnabled, onChanged: (v) => setState(() => _mqttEnabled = v)),
        TextField(controller: _mqttBrokerCtrl, decoration: const InputDecoration(labelText: 'Broker Host')),
        const SizedBox(height: 8),
        TextField(controller: _mqttPortCtrl, decoration: const InputDecoration(labelText: 'Broker Port'), keyboardType: TextInputType.number),
      ]),
    );
  }
}
"""

# ─── System health page ───
files["features/system_health/system_health_page.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/protocol/transport/transport_manager.dart';
import 'package:opensynaptic_dashboard/data/database/database_helper.dart';
import 'package:opensynaptic_dashboard/widgets/kpi_card.dart';

class SystemHealthPage extends ConsumerStatefulWidget {
  const SystemHealthPage({super.key});
  @override
  ConsumerState<SystemHealthPage> createState() => _SystemHealthPageState();
}
class _SystemHealthPageState extends ConsumerState<SystemHealthPage> {
  int _dbSizeKb = 0;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final size = await DatabaseHelper.instance.getDatabaseSize();
    if (mounted) setState(() => _dbSizeKb = size ~/ 1024);
  }
  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(transportStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('System Health')),
      body: stats.when(
        data: (s) => SingleChildScrollView(padding: const EdgeInsets.all(8), child: Column(children: [
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.6, children: [
            KpiCard(title: 'UDP Status', value: s.udpConnected ? 'Connected' : 'Disconnected', icon: Icons.cable, color: s.udpConnected ? AppColors.online : AppColors.offline),
            KpiCard(title: 'MQTT Status', value: s.mqttConnected ? 'Connected' : 'Disconnected', icon: Icons.cloud, color: s.mqttConnected ? AppColors.online : AppColors.offline),
            KpiCard(title: 'Messages/sec', value: '${s.messagesPerSecond}', icon: Icons.speed, color: AppColors.info),
            KpiCard(title: 'Total Messages', value: '${s.totalMessages}', icon: Icons.message, color: AppColors.primary),
          ]),
          KpiCard(title: 'Database Size', value: '$_dbSizeKb KB', icon: Icons.storage, color: AppColors.secondary),
        ])),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
"""

# ─── Main app shell ───
files["app.dart"] = r"""import 'package:flutter/material.dart';
import 'package:opensynaptic_dashboard/core/theme/app_theme.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/features/dashboard/dashboard_page.dart';
import 'package:opensynaptic_dashboard/features/devices/devices_page.dart';
import 'package:opensynaptic_dashboard/features/map/map_page.dart';
import 'package:opensynaptic_dashboard/features/alerts/alerts_page.dart';
import 'package:opensynaptic_dashboard/features/settings/settings_page.dart';
import 'package:opensynaptic_dashboard/features/history/history_page.dart';
import 'package:opensynaptic_dashboard/features/rules_config/rules_config_page.dart';
import 'package:opensynaptic_dashboard/features/system_health/system_health_page.dart';

class OsDashboardApp extends StatelessWidget {
  const OsDashboardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenSynaptic Dashboard',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    DeviceListPage(),
    DeviceMapPage(),
    AlertsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.devices_other), label: 'Devices'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.notifications), label: 'Alerts'),
        ],
      ),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surface),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: const [
              Text('OpenSynaptic', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              SizedBox(height: 4),
              Text('IoT Dashboard v1.0', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ),
          ListTile(leading: const Icon(Icons.history), title: const Text('History'), onTap: () {
            Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
          }),
          ListTile(leading: const Icon(Icons.rule), title: const Text('Rules Engine'), onTap: () {
            Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesConfigPage()));
          }),
          ListTile(leading: const Icon(Icons.health_and_safety), title: const Text('System Health'), onTap: () {
            Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemHealthPage()));
          }),
          const Divider(),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {
            Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
        ]),
      ),
    );
  }
}
"""

# ─── main.dart ───
files["main.dart"] = r"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OsDashboardApp()));
}
"""

# Write all files
for rel_path, content in files.items():
    full_path = os.path.join(BASE, rel_path.replace("/", os.sep))
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content.lstrip("\n"))
    print(f"  OK: {rel_path}")

print(f"\nWrote {len(files)} files.")

