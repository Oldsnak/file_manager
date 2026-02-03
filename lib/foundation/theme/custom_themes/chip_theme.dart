import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class TChipTheme {
  TChipTheme._();

  static ChipThemeData lightChipTheme = ChipThemeData(
    disabledColor: TColors.softGrey,
    labelStyle: const TextStyle(color: TColors.textPrimary),
    selectedColor: TColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    checkmarkColor: TColors.textWhite,
    backgroundColor: TColors.lightOptionalContainer,
  );

  static ChipThemeData darkChipTheme = ChipThemeData(
    disabledColor: TColors.darkGrey,
    labelStyle: const TextStyle(color: TColors.textWhite),
    selectedColor: TColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    checkmarkColor: TColors.textWhite,
    backgroundColor: TColors.darkOptional,
  );
}
