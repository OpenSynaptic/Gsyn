import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/app.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/core/l10n/locale_provider.dart';
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
    final l = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
          title: Text(l.alertsTitle),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => AppShell.scaffoldKey.currentState?.openDrawer(),
          ),
          bottom: TabBar(controller: _tabCtrl, tabs: [
            Tab(text: l.alertCritical),
            Tab(text: l.alertWarning),
            Tab(text: l.alertInfo),
          ])),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildList(2, l), _buildList(1, l), _buildList(0, l),
      ]),
    );
  }
  Widget _buildList(int level, AppStrings l) {
    final filtered = _alerts.where((a) => a.level == level).toList();
    if (filtered.isEmpty) return Center(child: Text(l.noAlerts, style: const TextStyle(color: AppColors.textSecondary)));
    return RefreshIndicator(onRefresh: _load, child: ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final a = filtered[i];
        final color = a.level == 2 ? AppColors.danger : a.level == 1 ? AppColors.warning : AppColors.info;
        return Card(child: ListTile(
          leading: Icon(a.level == 2 ? Icons.error : a.level == 1 ? Icons.warning : Icons.info, color: color),
          title: Text(a.message, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('${l.deviceLabel}: ${a.deviceAid} • ${DateTime.fromMillisecondsSinceEpoch(a.createdMs).toString().substring(0, 16)}',
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
