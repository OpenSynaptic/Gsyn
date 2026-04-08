import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/core/theme/app_theme.dart';
import 'package:opensynaptic_dashboard/core/theme/theme_provider.dart';
import 'package:opensynaptic_dashboard/core/constants.dart';
import 'package:opensynaptic_dashboard/core/l10n/locale_provider.dart';
import 'package:opensynaptic_dashboard/features/dashboard/dashboard_page.dart';
import 'package:opensynaptic_dashboard/features/devices/devices_page.dart';
import 'package:opensynaptic_dashboard/features/map/map_page.dart';
import 'package:opensynaptic_dashboard/features/alerts/alerts_page.dart';
import 'package:opensynaptic_dashboard/features/settings/settings_page.dart';
import 'package:opensynaptic_dashboard/features/history/history_page.dart';
import 'package:opensynaptic_dashboard/features/rules_config/rules_config_page.dart';
import 'package:opensynaptic_dashboard/features/system_health/system_health_page.dart';

class OsDashboardApp extends ConsumerWidget {
  const OsDashboardApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(themeProvider);
    final bg     = ref.watch(bgProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'OpenSynaptic Dashboard',
      theme: AppTheme.build(preset.seedColor, bg),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Global key — pages call [scaffoldKey.currentState?.openDrawer()] to open drawer.
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // 5 底部导航页：Dashboard / Devices / Alerts / Send / Settings
  // Map 移至抽屉（同 History / Rules / System Health）
  static final List<Widget> _pages = const [
    DashboardPage(),
    DeviceListPage(),
    AlertsPage(),
    Scaffold(body: Center(child: Text('Send'))), // placeholder
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final l = ref.watch(appStringsProvider);
      return Scaffold(
        key: AppShell.scaffoldKey,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: l.navDashboard),
            NavigationDestination(
                icon: const Icon(Icons.devices_other_outlined),
                selectedIcon: const Icon(Icons.devices_other),
                label: l.navDevices),
            NavigationDestination(
                icon: const Icon(Icons.notifications_outlined),
                selectedIcon: const Icon(Icons.notifications),
                label: l.navAlerts),
            NavigationDestination(
                icon: const Icon(Icons.send_outlined),
                selectedIcon: const Icon(Icons.send),
                label: l.navSend),
            NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l.navSettings),
          ],
        ),
        // 抽屉保留：地图 / 历史 / 规则 / 系统健康
        drawer: Drawer(
          child: ListView(padding: EdgeInsets.zero, children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.surface),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('OpenSynaptic',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(l.appSubtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            ListTile(
                leading: const Icon(Icons.map),
                title: Text(l.drawerMap),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DeviceMapPage()));
                }),
            ListTile(
                leading: const Icon(Icons.history),
                title: Text(l.drawerHistory),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HistoryPage()));
                }),
            ListTile(
                leading: const Icon(Icons.rule),
                title: Text(l.drawerRules),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RulesConfigPage()));
                }),
            ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: Text(l.drawerHealth),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SystemHealthPage()));
                }),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.settings),
                title: Text(l.navSettings),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _index = 4);
                }),
          ]),
        ),
      );
    });
  }
}
