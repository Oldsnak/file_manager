import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class TCheckboxTheme {
  TCheckboxTheme._();

  static CheckboxThemeData lightCheckboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    checkColor: WidgetStateProperty.all(TColors.textWhite),
    fillColor: WidgetStateProperty.resolveWith((states) =>
    states.contains(WidgetState.selected)
        ? TColors.primary
        : Colors.transparent),
  );

  static CheckboxThemeData darkCheckboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    checkColor: WidgetStateProperty.all(TColors.textPrimary),
    fillColor: WidgetStateProperty.resolveWith((states) =>
    states.contains(WidgetState.selected)
        ? TColors.primary
        : Colors.transparent),
  );
}
