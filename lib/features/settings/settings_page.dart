import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gsyn/app.dart';
import 'package:gsyn/core/constants.dart';
import 'package:gsyn/core/l10n/locale_provider.dart';
import 'package:gsyn/core/theme/theme_provider.dart';
import 'package:gsyn/data/database/database_helper.dart';
import 'package:gsyn/data/repositories/repositories.dart';
import 'package:gsyn/features/dashboard/dashboard_config.dart';
import 'package:gsyn/protocol/transport/transport_manager.dart';

// ── Tile-provider constants & provider ────────────────────────────────────────
const kTileUrlPrefKey = 'map_tile_url';
const kDefaultTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

const _kTilePresets = <String, String>{
  'OpenStreetMap': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  'CartoDB Light':
      'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
  'CartoDB Dark':
      'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
  'Stadia Alidade Dark':
      'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png',
  'Custom': '',
};

final tileUrlProvider = StateProvider<String>((ref) => kDefaultTileUrl);

// ── Main Settings page ────────────────────────────────────────────────────────
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => AppShell.scaffoldKey.currentState?.openDrawer(),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(
              icon: const Icon(Icons.cable, size: 18),
              text: l.settingsTabConnect,
            ),
            Tab(
              icon: const Icon(Icons.widgets, size: 18),
              text: l.settingsTabCards,
            ),
            Tab(
              icon: const Icon(Icons.palette, size: 18),
              text: l.settingsTabTheme,
            ),
            Tab(
              icon: const Icon(Icons.info_outline, size: 18),
              text: l.settingsTabInfo,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _ConnectionTab(),
          _CardsTab(),
          _ThemeTab(),
          _InfoTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 1 — Connection
// ═══════════════════════════════════════════════════════════════════════════════
class _ConnectionTab extends ConsumerStatefulWidget {
  const _ConnectionTab();
  @override
  ConsumerState<_ConnectionTab> createState() => _ConnectionTabState();
}

class _ConnectionTabState extends ConsumerState<_ConnectionTab> {
  final _udpHostCtrl = TextEditingController(text: '0.0.0.0');
  final _udpPortCtrl = TextEditingController(text: '9876');
  final _mqttBrokerCtrl = TextEditingController(text: 'localhost');
  final _mqttPortCtrl = TextEditingController(text: '1883');
  final _customTileCtrl = TextEditingController();
  final _btAddressCtrl = TextEditingController();
  final _btPortCtrl = TextEditingController(text: '9877');
  bool _udpEnabled = true;
  bool _mqttEnabled = false;
  bool _btEnabled = false;
  String _tilePreset = 'OpenStreetMap';
  String _wifiStatus = '';

  @override
  void initState() {
    super.initState();
    _wifiStatus = ref.read(appStringsProvider).detecting;
    _load();
    _checkWifi();
  }

  @override
  void dispose() {
    _udpHostCtrl.dispose();
    _udpPortCtrl.dispose();
    _mqttBrokerCtrl.dispose();
    _mqttPortCtrl.dispose();
    _customTileCtrl.dispose();
    _btAddressCtrl.dispose();
    _btPortCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkWifi() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final labels = result
          .map((r) {
            switch (r) {
              case ConnectivityResult.wifi:
                return '✅ Wi-Fi';
              case ConnectivityResult.mobile:
                return '📶 Mobile';
              case ConnectivityResult.ethernet:
                return '🔌 Ethernet';
              case ConnectivityResult.bluetooth:
                return '🔵 Bluetooth';
              default:
                return ref.read(appStringsProvider).noNetwork;
            }
          })
          .join('  ');
      if (mounted) {
        setState(
          () => _wifiStatus = labels.isEmpty
              ? ref.read(appStringsProvider).noNetwork
              : labels,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _wifiStatus = ref.read(appStringsProvider).detectFailed);
      }
    }
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final savedUrl = p.getString(kTileUrlPrefKey) ?? kDefaultTileUrl;
    final matched = _kTilePresets.entries
        .firstWhere(
          (e) => e.value == savedUrl,
          orElse: () => const MapEntry('Custom', ''),
        )
        .key;
    setState(() {
      _udpHostCtrl.text = p.getString('udp_host') ?? '0.0.0.0';
      _udpPortCtrl.text = p.getString('udp_port') ?? '9876';
      _mqttBrokerCtrl.text = p.getString('mqtt_broker') ?? 'localhost';
      _mqttPortCtrl.text = p.getString('mqtt_port') ?? '1883';
      _udpEnabled = p.getBool('udp_enabled') ?? true;
      _mqttEnabled = p.getBool('mqtt_enabled') ?? false;
      _btAddressCtrl.text = p.getString('bt_address') ?? '';
      _btPortCtrl.text = p.getString('bt_port') ?? '9877';
      _btEnabled = p.getBool('bt_enabled') ?? false;
      _tilePreset = matched;
      if (matched == 'Custom') _customTileCtrl.text = savedUrl;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('udp_host', _udpHostCtrl.text);
    await p.setString('udp_port', _udpPortCtrl.text);
    await p.setString('mqtt_broker', _mqttBrokerCtrl.text);
    await p.setString('mqtt_port', _mqttPortCtrl.text);
    await p.setBool('udp_enabled', _udpEnabled);
    await p.setBool('mqtt_enabled', _mqttEnabled);
    await p.setString('bt_address', _btAddressCtrl.text);
    await p.setString('bt_port', _btPortCtrl.text);
    await p.setBool('bt_enabled', _btEnabled);

    final tileUrl = _tilePreset == 'Custom'
        ? _customTileCtrl.text.trim()
        : _kTilePresets[_tilePreset]!;
    await p.setString(kTileUrlPrefKey, tileUrl);
    ref.read(tileUrlProvider.notifier).state = tileUrl;

    final tm = ref.read(transportManagerProvider);
    if (_udpEnabled) {
      await tm.udp.listen(
        _udpHostCtrl.text,
        int.tryParse(_udpPortCtrl.text) ?? 9876,
      );
    } else {
      await tm.udp.stop();
    }
    if (_mqttEnabled) {
      await tm.mqtt.connect(
        broker: _mqttBrokerCtrl.text,
        port: int.tryParse(_mqttPortCtrl.text) ?? 1883,
      );
    } else {
      await tm.mqtt.disconnect();
    }
    if (mounted) {
      final l = ref.read(appStringsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.connSettingsSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(appStringsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── UDP ────────────────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.wifi, title: l.secUdp),
        SwitchListTile(
          title: Text(l.enableUdp),
          value: _udpEnabled,
          onChanged: (v) => setState(() => _udpEnabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _udpEnabled
              ? Column(
                  children: [
                    TextField(
                      controller: _udpHostCtrl,
                      decoration: InputDecoration(
                        labelText: l.listenAddr,
                        hintText: l.listenAddrHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _udpPortCtrl,
                      decoration: InputDecoration(labelText: l.listenPort),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // ── MQTT ────────────────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.cloud, title: l.secMqtt),
        SwitchListTile(
          title: Text(l.enableMqtt),
          value: _mqttEnabled,
          onChanged: (v) => setState(() => _mqttEnabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _mqttEnabled
              ? Column(
                  children: [
                    TextField(
                      controller: _mqttBrokerCtrl,
                      decoration: InputDecoration(labelText: l.mqttBroker),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mqttPortCtrl,
                      decoration: InputDecoration(labelText: l.mqttPort),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // ── Map Tile ────────────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.map, title: l.secMapTile),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _tilePreset,
          decoration: InputDecoration(labelText: l.tileProviderLabel),
          items: _kTilePresets.keys
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) => setState(() => _tilePreset = v!),
        ),
        if (_tilePreset == 'Custom') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customTileCtrl,
            decoration: InputDecoration(
              labelText: l.customTileUrl,
              hintText: 'https://example.com/{z}/{x}/{y}.png',
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l.tileCurrentUrl(
            _tilePreset == 'Custom'
                ? (_customTileCtrl.text.isEmpty
                      ? '(未填写)'
                      : _customTileCtrl.text)
                : _kTilePresets[_tilePreset]!,
          ),
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(l.saveConnSettings),
          ),
        ),

        const SizedBox(height: 32),

        // ── WiFi 网络状态 ────────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.wifi, title: l.secWifi),
        const SizedBox(height: 4),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.signal_wifi_statusbar_4_bar,
                  size: 20,
                  color: AppColors.info,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _wifiStatus,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _checkWifi,
                  tooltip: l.refresh,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.wifiHint,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 24),

        // ── 蓝牙连接 ─────────────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.bluetooth, title: l.secBluetooth),
        SwitchListTile(
          title: Text(l.enableBluetooth),
          subtitle: Text(
            l.btExperimentalHint,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          value: _btEnabled,
          onChanged: (v) => setState(() => _btEnabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _btEnabled
              ? Column(
                  children: [
                    TextField(
                      controller: _btAddressCtrl,
                      decoration: InputDecoration(
                        labelText: l.btMacLabel,
                        hintText: 'AA:BB:CC:DD:EE:FF',
                        prefixIcon: const Icon(Icons.bluetooth_searching),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _btPortCtrl,
                      decoration: InputDecoration(
                        labelText: l.btPortLabel,
                        hintText: '9877',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.btInstructions,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2 — Cards
// ═══════════════════════════════════════════════════════════════════════════════
class _CardsTab extends ConsumerStatefulWidget {
  const _CardsTab();
  @override
  ConsumerState<_CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends ConsumerState<_CardsTab> {
  late DashboardCardConfig _cfg;

  @override
  void initState() {
    super.initState();
    _cfg = ref.read(dashboardConfigProvider);
  }

  void _save() {
    ref.read(dashboardConfigProvider.notifier).save(_cfg);
    final l = ref.read(appStringsProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.cardSettingsSaved)));
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChange) =>
      SwitchListTile(
        dense: true,
        title: Text(label),
        value: value,
        onChanged: (v) {
          setState(() => onChange(v));
        },
      );

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(appStringsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(icon: Icons.grid_view, title: l.secKpi),
        _toggle(
          l.cardDevicesLabel,
          _cfg.kpiDevices,
          (v) => _cfg = _cfg.copyWith(kpiDevices: v),
        ),
        _toggle(
          l.cardOnlineRateLabel,
          _cfg.kpiOnlineRate,
          (v) => _cfg = _cfg.copyWith(kpiOnlineRate: v),
        ),
        _toggle(
          l.cardAlertsLabel,
          _cfg.kpiAlerts,
          (v) => _cfg = _cfg.copyWith(kpiAlerts: v),
        ),
        _toggle(
          l.cardThroughputLabel,
          _cfg.kpiThroughput,
          (v) => _cfg = _cfg.copyWith(kpiThroughput: v),
        ),

        const Divider(),
        _SectionHeader(icon: Icons.show_chart, title: l.secLineChart),
        _toggle(
          l.toggleTempChart,
          _cfg.chartTemp,
          (v) => _cfg = _cfg.copyWith(chartTemp: v),
        ),
        _toggle(
          l.toggleHumChart,
          _cfg.chartHumidity,
          (v) => _cfg = _cfg.copyWith(chartHumidity: v),
        ),

        const Divider(),
        _SectionHeader(icon: Icons.speed, title: l.secGauges),
        _toggle(
          l.toggleGaugesRow1,
          _cfg.gaugesRow1,
          (v) => _cfg = _cfg.copyWith(gaugesRow1: v),
        ),
        _toggle(
          l.toggleGaugesRow2,
          _cfg.gaugesRow2,
          (v) => _cfg = _cfg.copyWith(gaugesRow2: v),
        ),

        const Divider(),
        _SectionHeader(icon: Icons.bar_chart, title: l.secCharts),
        _toggle(
          l.toggleBarChart,
          _cfg.barChart,
          (v) => _cfg = _cfg.copyWith(barChart: v),
        ),
        _toggle(
          l.togglePieChart,
          _cfg.pieChart,
          (v) => _cfg = _cfg.copyWith(pieChart: v),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(l.saveCardSettings),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 3 — Theme
// ═══════════════════════════════════════════════════════════════════════════════
class _ThemeTab extends ConsumerWidget {
  const _ThemeTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAccent = ref.watch(themeProvider);
    final currentBg = ref.watch(bgProvider);
    final Locale? currentLocale = ref.watch(localeProvider);
    final accentNotifier = ref.read(themeProvider.notifier);
    final bgNotifier = ref.read(bgProvider.notifier);
    final localeNotifier = ref.read(localeProvider.notifier);
    final l = ref.watch(appStringsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Accent color ───────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.palette, title: l.secAccent),
        const SizedBox(height: 4),
        Text(
          l.accentHint,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AppThemePreset.values.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (ctx, i) {
            final p = AppThemePreset.values[i];
            final sel = p == currentAccent;
            return GestureDetector(
              onTap: () => accentNotifier.select(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? p.seedColor : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.seedColor,
                        shape: BoxShape.circle,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: p.seedColor.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: sel
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      p.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        color: sel
                            ? p.seedColor
                            : Theme.of(
                                ctx,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const Divider(height: 28),

        // ── Background color ───────────────────────────────────────────────────
        _SectionHeader(icon: Icons.contrast, title: l.secBg),
        const SizedBox(height: 4),
        Text(
          l.bgHint,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),

        // ─ Dark group ─
        Row(
          children: [
            Icon(
              Icons.dark_mode,
              size: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              l.bgGroupDark,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BgPresetGrid(
          presets: AppBgPreset.values.where((p) => !p.isLight).toList(),
          currentBg: currentBg,
          currentAccent: currentAccent,
          onSelect: bgNotifier.select,
        ),

        const SizedBox(height: 16),

        // ─ Light group ─
        Row(
          children: [
            Icon(
              Icons.light_mode,
              size: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              l.bgGroupLight,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BgPresetGrid(
          presets: AppBgPreset.values.where((p) => p.isLight).toList(),
          currentBg: currentBg,
          currentAccent: currentAccent,
          onSelect: bgNotifier.select,
        ),

        const Divider(height: 28),

        // ── Language ───────────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.language, title: l.secLanguage),
        const SizedBox(height: 4),
        Text(
          l.langHint,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Follow system
            Expanded(
              child: _LangButton(
                label: l.langSystem,
                icon: '🌐',
                selected: currentLocale == null,
                onTap: () => localeNotifier.setSystem(),
              ),
            ),
            const SizedBox(width: 8),
            // Chinese
            Expanded(
              child: _LangButton(
                label: '中文',
                icon: '🇨🇳',
                selected: currentLocale?.languageCode == 'zh',
                onTap: () => localeNotifier.setLocale(const Locale('zh')),
              ),
            ),
            const SizedBox(width: 8),
            // English
            Expanded(
              child: _LangButton(
                label: 'English',
                icon: '🇬🇧',
                selected: currentLocale?.languageCode == 'en',
                onTap: () => localeNotifier.setLocale(const Locale('en')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 4 — Info
// ═══════════════════════════════════════════════════════════════════════════════
class _InfoTab extends ConsumerStatefulWidget {
  const _InfoTab();
  @override
  ConsumerState<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends ConsumerState<_InfoTab> {
  List<dynamic> _devices = [];
  int _dbSizeKb = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final devs = await ref.read(deviceRepositoryProvider).getAllDevices();
    final sz = await DatabaseHelper.instance.getDatabaseSize();
    if (mounted) {
      setState(() {
        _devices = devs;
        _dbSizeKb = sz ~/ 1024;
      });
    }
  }

  Future<void> _pruneData() async {
    final l = ref.read(appStringsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.pruneTitle),
        content: Text(l.pruneMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.pruneOldData(7);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.pruneDone)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = ref.watch(appStringsProvider);
    final stats = ref.watch(transportStatsProvider);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── App info ─────────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.apps, title: l.secAppInfo),
          _InfoRow(l.infoAppName, 'Gsyn'),
          _InfoRow(l.infoVersion, 'v1.0.0'),
          _InfoRow(l.infoProtocol, 'OpenSynaptic Wire Protocol'),
          _InfoRow(l.infoDbSize, '$_dbSizeKb KB'),

          const Divider(height: 32),

          // ── Transport status ──────────────────────────────────────────────────
          _SectionHeader(icon: Icons.cable, title: l.secTransport),
          stats.when(
            data: (s) => Column(
              children: [
                _InfoRow(
                  l.infoUdpStatus,
                  s.udpConnected ? l.connectedBadge : l.disconnectedBadge,
                ),
                _InfoRow(
                  l.infoMqttStatus,
                  s.mqttConnected ? l.connectedBadge : l.disconnectedBadge,
                ),
                _InfoRow(l.infoMsgPerSec, '${s.messagesPerSecond}'),
                _InfoRow(l.infoTotalMsg, '${s.totalMessages}'),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text('${l.errorPrefix}$e'),
          ),

          const Divider(height: 32),

          // ── Known devices / AIDs ──────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.devices,
            title: l.knownDevicesCount(_devices.length),
          ),
          if (_devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l.noDeviceData,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ..._devices.map((d) {
              final on = (d.status == 'online');
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.memory,
                  size: 18,
                  color: on ? AppColors.online : AppColors.offline,
                ),
                title: Text(
                  d.name.isNotEmpty ? d.name : '${l.devicePrefix} ${d.aid}',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  'AID: ${d.aid}  |  ${d.transportType.toUpperCase()}  |  ${d.status}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  d.lastSeenMs > 0 ? _ago(d.lastSeenMs) : '—',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }),

          const Divider(height: 32),

          // ── Maintenance ───────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.build, title: l.secMaintenance),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pruneData,
              icon: const Icon(Icons.delete_sweep, color: AppColors.warning),
              label: Text(
                l.pruneBtn,
                style: const TextStyle(color: AppColors.warning),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ago(int ms) {
    final diff = DateTime.now().millisecondsSinceEpoch - ms;
    if (diff < 60000) return '${diff ~/ 1000}s ago';
    if (diff < 3600000) return '${diff ~/ 60000}m ago';
    return '${diff ~/ 3600000}h ago';
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

/// Reusable grid that renders background-preset swatches.
class _BgPresetGrid extends StatelessWidget {
  final List<AppBgPreset> presets;
  final AppBgPreset currentBg;
  final AppThemePreset currentAccent;
  final void Function(AppBgPreset) onSelect;

  const _BgPresetGrid({
    required this.presets,
    required this.currentBg,
    required this.currentAccent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: presets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (_, i) {
        final bg = presets[i];
        final sel = bg == currentBg;
        // For light presets the check icon should be dark for visibility
        final checkColor = bg.isLight ? Colors.black54 : Colors.white;
        // Label text color: on light swatches use dark ink
        final labelColor = sel
            ? currentAccent.seedColor
            : (bg.isLight ? const Color(0xFF5F6368) : AppColors.textSecondary);
        return GestureDetector(
          onTap: () => onSelect(bg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel ? currentAccent.seedColor : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: bg.isLight
                  ? [
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Three-layer colour preview
                  Column(
                    children: [
                      Expanded(flex: 2, child: Container(color: bg.background)),
                      Expanded(child: Container(color: bg.surface)),
                      Expanded(child: Container(color: bg.card)),
                    ],
                  ),
                  // Label overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      color: bg.background.withValues(alpha: 0.85),
                      child: Text(
                        bg.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: labelColor,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  if (sel)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: checkColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Language selection button.
class _LangButton extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;
  const _LangButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurface.withValues(alpha: 0.6);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              Icon(Icons.check_circle, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
