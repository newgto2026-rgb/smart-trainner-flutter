import 'package:flutter/material.dart';

class SmartTrainnerColors {
  const SmartTrainnerColors._();

  static const ink = Color(0xFF10141F);
  static const muted = Color(0xFF687180);
  static const paper = Color(0xFFF6FAFC);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const line = Color(0xFFD8E6EE);
  static const coral = Color(0xFF1187C8);
  static const coralSoft = Color(0xFFE4F6FF);
  static const green = Color(0xFF1E8AA5);
}

ThemeData smartTrainnerTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: SmartTrainnerColors.coral),
    useMaterial3: true,
    scaffoldBackgroundColor: SmartTrainnerColors.paper,
    visualDensity: VisualDensity.standard,
  );
}
