import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class TTextTheme {
  TTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: TColors.black),
    headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: TColors.black),
    headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: TColors.black),

    titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: TColors.black),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: TColors.black),
    titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: TColors.black),

    bodyLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TColors.black),
    bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: TColors.black),
    bodySmall: const TextStyle(fontSize: 14, color: TColors.black),

    labelLarge: const TextStyle(fontSize: 12, color: TColors.black),
    labelMedium: const TextStyle(fontSize: 12, color: TColors.black),
  );

  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: TColors.white),
    headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: TColors.white),
    headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: TColors.white),

    titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: TColors.white),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: TColors.white),
    titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: TColors.white),

    bodyLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TColors.white),
    bodyMedium: const TextStyle(fontSize: 14, color: TColors.white),
    bodySmall: const TextStyle(fontSize: 14, color: TColors.white),

    labelLarge: const TextStyle(fontSize: 12, color: TColors.white),
    labelMedium: const TextStyle(fontSize: 12, color: TColors.white),
  );
}
