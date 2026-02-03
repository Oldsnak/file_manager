import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class TAppBarTheme {
  TAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TColors.textPrimary, size: 24),
    actionsIconTheme: IconThemeData(color: TColors.textPrimary, size: 24),
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: TColors.textPrimary,
    ),
  );

  static const darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: TColors.darkSecondary,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TColors.textWhite, size: 24),
    actionsIconTheme: IconThemeData(color: TColors.textWhite, size: 24),
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: TColors.textWhite,
    ),
  );
}
