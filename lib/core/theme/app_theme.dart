import 'package:flutter/material.dart';

ThemeData buildAppTheme(bool dark) {
  final primary = dark ? const Color(0xFF4C73FF) : const Color(0xFF3F6DFF);
  final surface = dark ? const Color(0xFF0F1721) : Colors.white;
  final mutedSurface = dark
      ? const Color.fromRGBO(255, 255, 255, 0.07)
      : const Color(0xFFF1F4FA);
  final stroke = dark
      ? const Color.fromRGBO(255, 255, 255, 0.08)
      : const Color(0xFFE6EBF3);

  final textTheme = ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: '.SF Pro Text',
  ).textTheme;

  return ThemeData(
    useMaterial3: false,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: surface,
      primary: primary,
    ),
    textTheme: textTheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF596271)
        : const Color(0xFFEAF0F8),
    cardColor: surface,
    dividerColor: stroke,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: dark
        ? const Color.fromRGBO(255, 255, 255, 0.04)
        : const Color.fromRGBO(63, 109, 255, 0.05),
    iconTheme: IconThemeData(
      color: dark ? const Color(0xFFD7DDE8) : const Color(0xFF1F2A3A),
      size: 19,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: mutedSurface,
      hintStyle: TextStyle(
        color: dark ? Colors.white38 : const Color(0xFF9AA4B4),
        fontSize: 13,
      ),
      prefixIconColor: dark ? Colors.white38 : const Color(0xFF8E98A9),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(18),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primary.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(18),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      isDense: true,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 3,
      overlayShape: SliderComponentShape.noOverlay,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      activeTrackColor: primary,
      inactiveTrackColor: dark
          ? const Color.fromRGBO(255, 255, 255, 0.16)
          : const Color(0xFFE2E7F0),
      thumbColor: primary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? Colors.white : const Color(0xFF1E2735),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        side: BorderSide(color: stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: dark
            ? const Color(0xFFD8DEE8)
            : const Color(0xFF263244),
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
