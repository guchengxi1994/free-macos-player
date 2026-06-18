import 'package:flutter/material.dart';

class AppPalette {
  AppPalette({
    required this.pageGradient,
    required this.shellBackground,
    required this.panelBackground,
    required this.panelSecondaryBackground,
    required this.sidebarBackground,
    required this.stroke,
    required this.softText,
    required this.primary,
    required this.primarySoft,
    required this.shadow,
    required this.overlay,
  });

  final List<Color> pageGradient;
  final Color shellBackground;
  final Color panelBackground;
  final Color panelSecondaryBackground;
  final Color sidebarBackground;
  final Color stroke;
  final Color softText;
  final Color primary;
  final Color primarySoft;
  final Color shadow;
  final Color overlay;

  static AppPalette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return AppPalette(
        pageGradient: const [Color(0xFF68717F), Color(0xFF313945)],
        shellBackground: const Color(0xFF0B121B),
        panelBackground: const Color(0xFF0F1721),
        panelSecondaryBackground: const Color(0xFF151E29),
        sidebarBackground: const Color(0xFF0A111A),
        stroke: const Color.fromRGBO(255, 255, 255, 0.075),
        softText: const Color(0xFF8E98AA),
        primary: const Color(0xFF4C73FF),
        primarySoft: const Color.fromRGBO(76, 115, 255, 0.16),
        shadow: const Color.fromRGBO(0, 0, 0, 0.34),
        overlay: const Color.fromRGBO(4, 8, 14, 0.62),
      );
    }

    return AppPalette(
      pageGradient: const [Color(0xFFF1F5FB), Color(0xFFDDE8F5)],
      shellBackground: const Color(0xFFFDFEFF),
      panelBackground: Colors.white,
      panelSecondaryBackground: const Color(0xFFF6F8FC),
      sidebarBackground: const Color(0xFFFBFCFF),
      stroke: const Color(0xFFE6EBF3),
      softText: const Color(0xFF8B96A8),
      primary: const Color(0xFF3F6DFF),
      primarySoft: const Color.fromRGBO(63, 109, 255, 0.10),
      shadow: const Color.fromRGBO(43, 67, 104, 0.12),
      overlay: const Color.fromRGBO(255, 255, 255, 0.72),
    );
  }
}
