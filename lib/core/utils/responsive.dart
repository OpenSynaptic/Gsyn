// Responsive breakpoint helpers.
import 'package:flutter/material.dart';

enum ScreenClass { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static const double _mobileBreak  = 600;
  static const double _desktopBreak = 1024;

  static ScreenClass of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < _mobileBreak)  return ScreenClass.mobile;
    if (w < _desktopBreak) return ScreenClass.tablet;
    return ScreenClass.desktop;
  }

  static bool isMobile(BuildContext context)  => of(context) == ScreenClass.mobile;
  static bool isDesktop(BuildContext context) => of(context) != ScreenClass.mobile;
}

