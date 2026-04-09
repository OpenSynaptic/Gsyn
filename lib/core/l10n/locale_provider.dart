/// Locale Riverpod providers — persisted to SharedPreferences.
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';

export 'app_strings.dart';

const _kLocalePrefKey = 'app_locale';
const _kLocaleSystem = 'system';

// ── Notifier ──────────────────────────────────────────────────────────────────
// null  = follow system locale
// Locale('zh') / Locale('en') = explicit user choice
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null); // default: follow system

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_kLocalePrefKey);
    if (code == null || code == _kLocaleSystem) {
      state = null;
    } else {
      state = Locale(code);
    }
  }

  /// Reset to system locale.
  Future<void> setSystem() async {
    state = null;
    (await SharedPreferences.getInstance()).setString(
      _kLocalePrefKey,
      _kLocaleSystem,
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    (await SharedPreferences.getInstance()).setString(
      _kLocalePrefKey,
      locale.languageCode,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
/// Resolves the *effective* locale: explicit choice, or system fallback clamped
/// to the two supported languages (zh / en).
Locale resolveLocale(Locale? chosen) {
  if (chosen != null) return chosen;
  final sys = PlatformDispatcher.instance.locale;
  return sys.languageCode.startsWith('zh')
      ? const Locale('zh')
      : const Locale('en');
}

// ── Providers ─────────────────────────────────────────────────────────────────
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final n = LocaleNotifier();
  n.load();
  return n;
});

/// Reactive [AppStrings] — rebuilds any watching widget when locale changes.
final appStringsProvider = Provider<AppStrings>((ref) {
  final chosen = ref.watch(localeProvider);
  final effective = resolveLocale(chosen);
  return AppStrings(effective.languageCode == 'zh');
});
