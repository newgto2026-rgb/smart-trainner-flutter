import 'package:flutter/material.dart';

class SmartTrainnerColors {
  const SmartTrainnerColors._();

  static const ink = Color(0xFF10141F);
  static const inkSoft = Color(0xFF1B2B3A);
  static const muted = Color(0xFF687180);
  static const paper = Color(0xFFF6FAFC);
  static const surface = Color(0xFFFFFCF8);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const line = Color(0xFFD8E6EE);
  static const coral = Color(0xFF1187C8);
  static const coralSoft = Color(0xFFE4F6FF);
  static const green = Color(0xFF1E8AA5);
  static const greenSoft = Color(0xFFE4F8FB);
  static const amber = Color(0xFF48C7F2);
  static const amberSoft = Color(0xFFE7F8FF);
  static const steel = Color(0xFF4D6678);
  static const steelSoft = Color(0xFFE9EEF1);
}

class SmartTrainnerGradients {
  const SmartTrainnerGradients._();

  static const screen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFFFFCF7), Color(0xFFF0FAFD), Color(0xFFF5F9FF)],
  );

  static const brandLight = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[Color(0xFFFFFCF8), Color(0xFFEAF8FF), Color(0xFFF1FBFF)],
  );
}

ThemeData smartTrainnerTheme() {
  const colorScheme = ColorScheme.light(
    primary: SmartTrainnerColors.coral,
    onPrimary: Colors.white,
    secondary: SmartTrainnerColors.green,
    onSecondary: Colors.white,
    tertiary: SmartTrainnerColors.amber,
    surface: SmartTrainnerColors.surface,
    onSurface: SmartTrainnerColors.ink,
    surfaceContainerHighest: SmartTrainnerColors.steelSoft,
    onSurfaceVariant: SmartTrainnerColors.muted,
    outline: SmartTrainnerColors.line,
    error: Color(0xFFB3261E),
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: SmartTrainnerColors.paper,
    visualDensity: VisualDensity.standard,
    fontFamily: 'Roboto',
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SmartTrainnerColors.surfaceRaised,
      indicatorColor: SmartTrainnerColors.coralSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? SmartTrainnerColors.coral
              : SmartTrainnerColors.muted,
          fontWeight: FontWeight.w700,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? SmartTrainnerColors.coral
              : SmartTrainnerColors.muted,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SmartTrainnerColors.coral,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SmartTrainnerColors.coral,
        side: const BorderSide(color: SmartTrainnerColors.line),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: SmartTrainnerColors.steelSoft,
      selectedColor: SmartTrainnerColors.coralSoft,
      side: const BorderSide(color: SmartTrainnerColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(
        color: SmartTrainnerColors.ink,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SmartTrainnerColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SmartTrainnerColors.coral),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: SmartTrainnerColors.surfaceRaised,
    ),
  );
}
