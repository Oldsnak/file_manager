import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class TElevatedButtonTheme {
  TElevatedButtonTheme._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 8,
      shadowColor: TColors.primary.withOpacity(0.2),
      foregroundColor: TColors.textWhite,
      backgroundColor: TColors.buttonPrimary,
      disabledForegroundColor: TColors.grey,
      disabledBackgroundColor: TColors.buttonDisabled,
      side: const BorderSide(color: TColors.primary),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: TSizes.lg),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 8,
      foregroundColor: TColors.textWhite,
      backgroundColor: TColors.primary,
      disabledForegroundColor: TColors.darkGrey,
      disabledBackgroundColor: TColors.darkOptional,
      side: const BorderSide(color: TColors.darkPrimary),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: TSizes.lg),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
