import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gsyn/app.dart';
import 'package:gsyn/features/settings/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Desktop SQLite init (Windows / Linux / macOS) ──────────────────────────
  if (!kIsWeb) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        break;
      default:
        break;
    }
  }

  // Restore saved tile URL so map uses it immediately on launch
  final prefs = await SharedPreferences.getInstance();
  final savedTileUrl = prefs.getString(kTileUrlPrefKey) ?? kDefaultTileUrl;
  runApp(
    ProviderScope(
      overrides: [tileUrlProvider.overrideWith((ref) => savedTileUrl)],
      child: const OsDashboardApp(),
    ),
  );
}
