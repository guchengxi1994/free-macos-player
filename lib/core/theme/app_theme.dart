import 'package:flutter/material.dart';

ThemeData buildAppTheme(bool dark) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4C74FF),
    brightness: dark ? Brightness.dark : Brightness.light,
    surface: dark ? const Color(0xFF11161F) : const Color(0xFFF7F9FD),
  );

  final textTheme = ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: '.SF Pro Text',
  ).textTheme;

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF596273) : const Color(0xFFE8EEF8),
    cardColor: dark ? const Color(0xFF121821) : Colors.white,
    dividerColor: dark ? Colors.white10 : const Color(0xFFE6EBF4),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark
          ? const Color.fromRGBO(255, 255, 255, 0.06)
          : const Color(0xFFF1F4FA),
      hintStyle: TextStyle(
        color: dark ? Colors.white38 : const Color(0xFF98A2B3),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(18),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: dark
              ? const Color(0xFF6F8BFF)
              : const Color(0xFF4C74FF),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 3,
      overlayShape: SliderComponentShape.noOverlay,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
    ),
  );
}
