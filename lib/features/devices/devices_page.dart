import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsyn/app.dart';
import 'package:gsyn/core/constants.dart';
import 'package:gsyn/core/l10n/locale_provider.dart';
import 'package:gsyn/data/models/models.dart';
import 'package:gsyn/data/repositories/repositories.dart';

class DeviceListPage extends ConsumerStatefulWidget {
  const DeviceListPage({super.key});
  @override
  ConsumerState<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends ConsumerState<DeviceListPage> {
  List<Device> _devices = [];
  String _search = '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await ref.read(deviceRepositoryProvider).getAllDevices();
    if (mounted) setState(() => _devices = d);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(appStringsProvider);
    final list = _devices.where((d) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return d.name.toLowerCase().contains(q) || d.aid.toString().contains(q);
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.devicesTitle),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l.searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final d = list[i];
                  final on = d.status == 'online';
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.devices_other,
                        color: on ? AppColors.online : AppColors.offline,
                      ),
                      title: Text(
                        d.name.isNotEmpty
                            ? d.name
                            : '${l.devicePrefix} ${d.aid}',
                      ),
                      subtitle: Text(
                        'AID: ${d.aid}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        d.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: on ? AppColors.online : AppColors.offline,
                        ),
                      ),
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => DeviceDetailPage(device: d),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await ref
        .read(sensorDataRepositoryProvider)
        .getLatestByDevice(widget.device.aid);
    if (mounted) setState(() => _readings = r);
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.device.name.isNotEmpty
              ? widget.device.name
              : '${l.devicePrefix} ${widget.device.aid}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'AID: ${widget.device.aid} | ${widget.device.transportType.toUpperCase()} | ${widget.device.status}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.latestReadings,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          ..._readings.map(
            (r) => Card(
              child: ListTile(
                title: Text(r.sensorId),
                trailing: Text(
                  '${r.value.toStringAsFixed(2)} ${r.unit}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.network_ping),
                        label: const Text('PING'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('RESET'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
