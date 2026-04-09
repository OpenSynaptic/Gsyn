import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsyn/core/constants.dart';
import 'package:gsyn/core/l10n/locale_provider.dart';
import 'package:gsyn/protocol/transport/transport_manager.dart';
import 'package:gsyn/data/database/database_helper.dart';
import 'package:gsyn/widgets/kpi_card.dart';

class SystemHealthPage extends ConsumerStatefulWidget {
  const SystemHealthPage({super.key});
  @override
  ConsumerState<SystemHealthPage> createState() => _SystemHealthPageState();
}

class _SystemHealthPageState extends ConsumerState<SystemHealthPage> {
  int _dbSizeKb = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final size = await DatabaseHelper.instance.getDatabaseSize();
    if (mounted) setState(() => _dbSizeKb = size ~/ 1024);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(transportStatsProvider);
    final l = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.healthTitle)),
      body: stats.when(
        data: (s) => SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                children: [
                  KpiCard(
                    title: l.udpStatus,
                    value: s.udpConnected
                        ? l.statusConnected
                        : l.statusDisconnected,
                    icon: Icons.cable,
                    color: s.udpConnected
                        ? AppColors.online
                        : AppColors.offline,
                  ),
                  KpiCard(
                    title: l.mqttStatus,
                    value: s.mqttConnected
                        ? l.statusConnected
                        : l.statusDisconnected,
                    icon: Icons.cloud,
                    color: s.mqttConnected
                        ? AppColors.online
                        : AppColors.offline,
                  ),
                  KpiCard(
                    title: l.messagesPerSec,
                    value: '${s.messagesPerSecond}',
                    icon: Icons.speed,
                    color: AppColors.info,
                  ),
                  KpiCard(
                    title: l.totalMessages,
                    value: '${s.totalMessages}',
                    icon: Icons.message,
                    color: AppColors.primary,
                  ),
                ],
              ),
              KpiCard(
                title: l.dbSize,
                value: '$_dbSizeKb KB',
                icon: Icons.storage,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l.errorPrefix}$e')),
      ),
    );
  }
}
