/// App theme preset system — color seed + background preset + StateNotifiers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemePrefKey = 'app_theme_preset';
const _kBgPrefKey = 'app_bg_preset';

// ── Accent color presets ──────────────────────────────────────────────────────
enum AppThemePreset { deepBlue, teal, purple, amber, red, cyan, green, pink }

extension AppThemePresetExt on AppThemePreset {
  Color get seedColor {
    switch (this) {
      case AppThemePreset.deepBlue:
        return const Color(0xFF1A73E8);
      case AppThemePreset.teal:
        return const Color(0xFF00897B);
      case AppThemePreset.purple:
        return const Color(0xFF7B1FA2);
      case AppThemePreset.amber:
        return const Color(0xFFFF8F00);
      case AppThemePreset.red:
        return const Color(0xFFD32F2F);
      case AppThemePreset.cyan:
        return const Color(0xFF0097A7);
      case AppThemePreset.green:
        return const Color(0xFF2E7D32);
      case AppThemePreset.pink:
        return const Color(0xFFC2185B);
    }
  }

  String get label {
    switch (this) {
      case AppThemePreset.deepBlue:
        return 'Deep Blue';
      case AppThemePreset.teal:
        return 'Teal';
      case AppThemePreset.purple:
        return 'Purple';
      case AppThemePreset.amber:
        return 'Amber';
      case AppThemePreset.red:
        return 'Red';
      case AppThemePreset.cyan:
        return 'Cyan';
      case AppThemePreset.green:
        return 'Green';
      case AppThemePreset.pink:
        return 'Pink';
    }
  }
}

// ── Background color presets ──────────────────────────────────────────────────
enum AppBgPreset {
  // ── Dark presets ──
  deepNavy, // default — blue-tinted dark
  darkSlate, // cool slate
  charcoal, // neutral grey
  trueBlack, // AMOLED pure black
  forestDark, // green-tinted dark
  warmDark, // warm brownish dark
  // ── Light presets ──
  snowWhite, // clean white
  cloudGrey, // soft cool grey
  paperCream, // warm paper cream
  mintLight, // fresh mint green
  lavenderLight, // gentle lavender
  skyBlue, // light sky blue
}

extension AppBgPresetExt on AppBgPreset {
  /// True for light (浅色) presets.
  bool get isLight => index >= AppBgPreset.snowWhite.index;

  Color get background {
    switch (this) {
      case AppBgPreset.deepNavy:
        return const Color(0xFF0F1923);
      case AppBgPreset.darkSlate:
        return const Color(0xFF121420);
      case AppBgPreset.charcoal:
        return const Color(0xFF1A1A1A);
      case AppBgPreset.trueBlack:
        return const Color(0xFF080808);
      case AppBgPreset.forestDark:
        return const Color(0xFF0D1A0D);
      case AppBgPreset.warmDark:
        return const Color(0xFF1A1209);
      case AppBgPreset.snowWhite:
        return const Color(0xFFFAFAFA);
      case AppBgPreset.cloudGrey:
        return const Color(0xFFF1F3F4);
      case AppBgPreset.paperCream:
        return const Color(0xFFFFFDE7);
      case AppBgPreset.mintLight:
        return const Color(0xFFE8F5E9);
      case AppBgPreset.lavenderLight:
        return const Color(0xFFEDE7F6);
      case AppBgPreset.skyBlue:
        return const Color(0xFFE3F2FD);
    }
  }

  Color get surface {
    switch (this) {
      case AppBgPreset.deepNavy:
        return const Color(0xFF1B2838);
      case AppBgPreset.darkSlate:
        return const Color(0xFF1D2033);
      case AppBgPreset.charcoal:
        return const Color(0xFF262626);
      case AppBgPreset.trueBlack:
        return const Color(0xFF141414);
      case AppBgPreset.forestDark:
        return const Color(0xFF172617);
      case AppBgPreset.warmDark:
        return const Color(0xFF261D0F);
      case AppBgPreset.snowWhite:
        return const Color(0xFFFFFFFF);
      case AppBgPreset.cloudGrey:
        return const Color(0xFFFFFFFF);
      case AppBgPreset.paperCream:
        return const Color(0xFFFFFFFF);
      case AppBgPreset.mintLight:
        return const Color(0xFFFFFFFF);
      case AppBgPreset.lavenderLight:
        return const Color(0xFFFFFFFF);
      case AppBgPreset.skyBlue:
        return const Color(0xFFFFFFFF);
    }
  }

  Color get card {
    switch (this) {
      case AppBgPreset.deepNavy:
        return const Color(0xFF213040);
      case AppBgPreset.darkSlate:
        return const Color(0xFF252840);
      case AppBgPreset.charcoal:
        return const Color(0xFF303030);
      case AppBgPreset.trueBlack:
        return const Color(0xFF1E1E1E);
      case AppBgPreset.forestDark:
        return const Color(0xFF1F301F);
      case AppBgPreset.warmDark:
        return const Color(0xFF302318);
      case AppBgPreset.snowWhite:
        return const Color(0xFFF1F3F4);
      case AppBgPreset.cloudGrey:
        return const Color(0xFFE8EAED);
      case AppBgPreset.paperCream:
        return const Color(0xFFFFF9C4);
      case AppBgPreset.mintLight:
        return const Color(0xFFC8E6C9);
      case AppBgPreset.lavenderLight:
        return const Color(0xFFD1C4E9);
      case AppBgPreset.skyBlue:
        return const Color(0xFFBBDEFB);
    }
  }

  String get label {
    switch (this) {
      case AppBgPreset.deepNavy:
        return '深海蓝 (默认)';
      case AppBgPreset.darkSlate:
        return '暗石板';
      case AppBgPreset.charcoal:
        return '炭灰';
      case AppBgPreset.trueBlack:
        return '纯黑 (AMOLED)';
      case AppBgPreset.forestDark:
        return '森林暗绿';
      case AppBgPreset.warmDark:
        return '暖棕暗';
      case AppBgPreset.snowWhite:
        return '雪白';
      case AppBgPreset.cloudGrey:
        return '云雾灰';
      case AppBgPreset.paperCream:
        return '纸张米黄';
      case AppBgPreset.mintLight:
        return '薄荷浅绿';
      case AppBgPreset.lavenderLight:
        return '薰衣草紫';
      case AppBgPreset.skyBlue:
        return '天空蓝';
    }
  }
}

// ── Accent notifier ───────────────────────────────────────────────────────────
class ThemeNotifier extends StateNotifier<AppThemePreset> {
  ThemeNotifier(super.state);
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final k = p.getString(_kThemePrefKey);
    if (k != null) {
      try {
        state = AppThemePreset.values.firstWhere((e) => e.name == k);
      } catch (_) {}
    }
  }

  Future<void> select(AppThemePreset preset) async {
    state = preset;
    (await SharedPreferences.getInstance()).setString(
      _kThemePrefKey,
      preset.name,
    );
  }
}

// ── Background notifier ───────────────────────────────────────────────────────
class BgNotifier extends StateNotifier<AppBgPreset> {
  BgNotifier(super.state);
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final k = p.getString(_kBgPrefKey);
    if (k != null) {
      try {
        state = AppBgPreset.values.firstWhere((e) => e.name == k);
      } catch (_) {}
    }
  }

  Future<void> select(AppBgPreset preset) async {
    state = preset;
    (await SharedPreferences.getInstance()).setString(_kBgPrefKey, preset.name);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemePreset>((
  ref,
) {
  final n = ThemeNotifier(AppThemePreset.deepBlue);
  n.load();
  return n;
});

final bgProvider = StateNotifierProvider<BgNotifier, AppBgPreset>((ref) {
  final n = BgNotifier(AppBgPreset.deepNavy);
  n.load();
  return n;
});
