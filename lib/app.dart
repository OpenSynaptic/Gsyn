import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opensynaptic_dashboard/core/theme/app_theme.dart';
import 'package:opensynaptic_dashboard/core/theme/theme_provider.dart';
import 'package:opensynaptic_dashboard/core/l10n/locale_provider.dart';
import 'package:opensynaptic_dashboard/core/utils/responsive.dart';
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

// ignore_for_file: prefer_const_literals_to_create_immutables
// _kDests contains function literals which cannot be const.

// ── Navigation destination model ──────────────────────────────────────────────
class _NavDest {
  final IconData icon;
  final IconData activeIcon;
  final String Function(AppStrings) label;
  const _NavDest(this.icon, this.activeIcon, this.label);
}

final List<_NavDest> _kDests = [
  _NavDest(Icons.dashboard_outlined,     Icons.dashboard,     (l) => l.navDashboard),
  _NavDest(Icons.devices_other_outlined, Icons.devices_other, (l) => l.navDevices),
  _NavDest(Icons.notifications_outlined, Icons.notifications, (l) => l.navAlerts),
  _NavDest(Icons.send_outlined,          Icons.send,          (l) => l.navSend),
  _NavDest(Icons.settings_outlined,      Icons.settings,      (l) => l.navSettings),
];

// ── AppShell ──────────────────────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static final List<Widget> _pages = const [
    DashboardPage(),
    DeviceListPage(),
    AlertsPage(),
    Scaffold(body: Center(child: Text('Send'))), // placeholder until send_page restored
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final l       = ref.watch(appStringsProvider);
      final desktop = Responsive.isDesktop(context);
      final body    = IndexedStack(index: _index, children: _pages);

      if (desktop) {
        // ── Desktop / Tablet layout: NavigationRail (left sidebar) ──────────
        return Scaffold(
          key: AppShell.scaffoldKey,
          body: Row(children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              extended: MediaQuery.of(context).size.width >= 1200,
              labelType: MediaQuery.of(context).size.width >= 1200
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.hub_outlined, size: 28),
                  const SizedBox(height: 2),
                  if (MediaQuery.of(context).size.width >= 1200)
                    const Text('OpenSynaptic',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _RailExtra(icon: Icons.map,             label: l.drawerMap,     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceMapPage()))),
                      _RailExtra(icon: Icons.history,         label: l.drawerHistory, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
                      _RailExtra(icon: Icons.rule,            label: l.drawerRules,   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesConfigPage()))),
                      _RailExtra(icon: Icons.health_and_safety, label: l.drawerHealth, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemHealthPage()))),
                    ]),
                  ),
                ),
              ),
              destinations: _kDests.map((d) => NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: Text(d.label(l)),
              )).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ]),
        );
      }

      // ── Mobile layout: bottom NavigationBar + drawer ─────────────────────
      return Scaffold(
        key: AppShell.scaffoldKey,
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _kDests.map((d) => NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.activeIcon),
            label: d.label(l),
          )).toList(),
        ),
        drawer: _AppDrawer(
          currentIndex: _index,
          onNav: (i) { Navigator.pop(context); setState(() => _index = i); },
        ),
      );
    });
  }
}

// ── Drawer (mobile only) ──────────────────────────────────────────────────────
class _AppDrawer extends ConsumerWidget {
  final int currentIndex;
  final void Function(int) onNav;
  const _AppDrawer({required this.currentIndex, required this.onNav});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(appStringsProvider);
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('OpenSynaptic',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(l.appSubtitle,
                  style: TextStyle(fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        ListTile(leading: const Icon(Icons.map),            title: Text(l.drawerMap),    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceMapPage())); }),
        ListTile(leading: const Icon(Icons.history),        title: Text(l.drawerHistory),onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())); }),
        ListTile(leading: const Icon(Icons.rule),           title: Text(l.drawerRules),  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesConfigPage())); }),
        ListTile(leading: const Icon(Icons.health_and_safety), title: Text(l.drawerHealth), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemHealthPage())); }),
        const Divider(),
        ListTile(leading: const Icon(Icons.settings), title: Text(l.navSettings), onTap: () => onNav(4)),
      ]),
    );
  }
}

// ── Rail extra button (desktop trailing) ──────────────────────────────────────
class _RailExtra extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RailExtra({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: label,
      onPressed: onTap,
    );
  }
}
