import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/core/l10n/locale_provider.dart';
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
    final l = ref.read(appStringsProvider);
    final rows = [[l.csvTimestamp, l.csvDeviceAid, l.csvSensor, l.csvValue, l.csvUnit]];
    for (final d in _data) {
      rows.add([DateTime.fromMillisecondsSinceEpoch(d.timestampMs).toIso8601String(), d.deviceAid.toString(), d.sensorId, d.value.toString(), d.unit]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.exportedTo(file.path))));
  }
  @override
  Widget build(BuildContext context) {
    final l = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.historyTitle), actions: [
        IconButton(icon: const Icon(Icons.file_download), onPressed: _export),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _query),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty ? Center(child: Text(l.noData, style: const TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
        itemCount: _data.length,
        itemBuilder: (ctx, i) {
          final d = _data[i];
          return Card(child: ListTile(
            dense: true,
            title: Text('${d.sensorId}: ${d.value.toStringAsFixed(2)} ${d.unit}'),
            subtitle: Text('${l.devicePrefix} ${d.deviceAid} • ${DateTime.fromMillisecondsSinceEpoch(d.timestampMs).toString().substring(0, 19)}',
                style: const TextStyle(fontSize: 11)),
          ));
        },
      ),
    );
  }
}
