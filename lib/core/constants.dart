/// App constants — colors, thresholds, unit codes.
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFF34A853);
  static const Color background = Color(0xFF0F1923);
  static const Color surface = Color(0xFF1B2838);
  static const Color card = Color(0xFF213040);
  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFF9AA0A6);

  // Status colors
  static const Color online = Color(0xFF34A853);
  static const Color offline = Color(0xFF5F6368);
  static const Color warning = Color(0xFFFBBC04);
  static const Color danger = Color(0xFFEA4335);
  static const Color info = Color(0xFF4285F4);

  // Threshold zone colors
  static const Color zoneNormal = Color(0xFF34A853);
  static const Color zoneWarning = Color(0xFFFBBC04);
  static const Color zoneDanger = Color(0xFFEA4335);

  // Chart palette
  static const List<Color> chartPalette = [
    Color(0xFF4285F4),
    Color(0xFF34A853),
    Color(0xFFFBBC04),
    Color(0xFFEA4335),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF9800),
    Color(0xFF607D8B),
  ];
}

class Thresholds {
  static const double tempWarning = 40.0;
  static const double tempDanger = 60.0;
  static const double humidityWarning = 80.0;
  static const double humidityDanger = 95.0;
  static const double pressureWarning = 1050.0;
  static const double pressureDanger = 1100.0;
  static const double onlineRateWarning = 0.9;
  static const double onlineRateDanger = 0.7;
}
