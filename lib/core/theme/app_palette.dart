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
        pageGradient: const [Color(0xFF657082), Color(0xFF2A313D)],
        shellBackground: const Color(0xFF131923),
        panelBackground: const Color(0xFF111821),
        panelSecondaryBackground: const Color(0xFF171F2B),
        sidebarBackground: const Color(0xFF0E141D),
        stroke: const Color.fromRGBO(255, 255, 255, 0.08),
        softText: const Color(0xFF8C97AA),
        primary: const Color(0xFF5278FF),
        primarySoft: const Color.fromRGBO(82, 120, 255, 0.18),
        shadow: const Color.fromRGBO(0, 0, 0, 0.26),
        overlay: const Color.fromRGBO(4, 8, 16, 0.68),
      );
    }

    return AppPalette(
      pageGradient: const [Color(0xFFEFF3FA), Color(0xFFDCE7F6)],
      shellBackground: Colors.white,
      panelBackground: Colors.white,
      panelSecondaryBackground: const Color(0xFFF7F9FD),
      sidebarBackground: const Color(0xFFF9FBFF),
      stroke: const Color(0xFFE9EEF6),
      softText: const Color(0xFF8D97A6),
      primary: const Color(0xFF4C74FF),
      primarySoft: const Color.fromRGBO(76, 116, 255, 0.10),
      shadow: const Color.fromRGBO(40, 67, 111, 0.10),
      overlay: const Color.fromRGBO(255, 255, 255, 0.66),
    );
  }
}
