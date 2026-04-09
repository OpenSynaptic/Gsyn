import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gsyn/core/constants.dart';
import 'package:gsyn/data/models/models.dart';
import 'package:gsyn/data/repositories/repositories.dart';
import 'package:gsyn/features/settings/settings_page.dart';

class DeviceMapPage extends ConsumerStatefulWidget {
  const DeviceMapPage({super.key});
  @override
  ConsumerState<DeviceMapPage> createState() => _DeviceMapPageState();
}

class _DeviceMapPageState extends ConsumerState<DeviceMapPage> {
  List<Device> _devices = [];
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
    final tileUrl = ref.watch(tileUrlProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Device Map')),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(30.0, 120.0),
          initialZoom: 5,
        ),
        children: [
          TileLayer(
            urlTemplate: tileUrl,
            userAgentPackageName: 'com.opensynaptic.gsyn',
          ),
          MarkerLayer(
            markers: _devices.where((d) => d.lat != 0 || d.lng != 0).map((d) {
              final on = d.status == 'online';
              return Marker(
                point: LatLng(d.lat, d.lng),
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_on,
                  color: on ? AppColors.online : AppColors.offline,
                  size: 36,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
