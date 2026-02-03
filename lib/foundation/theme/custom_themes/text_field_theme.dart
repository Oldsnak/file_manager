import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class TTextFormFieldTheme {
  TTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    prefixIconColor: TColors.primary,
    suffixIconColor: TColors.primary,
    labelStyle: const TextStyle(fontSize: 14, color: TColors.textPrimary),
    hintStyle: const TextStyle(fontSize: 14, color: TColors.textSecondary),
    floatingLabelStyle: const TextStyle(color: TColors.primary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: TColors.borderPrimary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: TColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: TColors.error),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    prefixIconColor: TColors.primary,
    suffixIconColor: TColors.primary,
    labelStyle: const TextStyle(fontSize: 14, color: TColors.textWhite),
    hintStyle: const TextStyle(fontSize: 14, color: TColors.darkGrey),
    floatingLabelStyle: const TextStyle(color: TColors.darkPrimary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: TColors.buttonSecondary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: TColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: TColors.error),
    ),
  );
}
