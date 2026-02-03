import 'package:flutter/cupertino.dart';
import '../../foundation/constants/sizes.dart';

class Spacing{
  static const EdgeInsetsGeometry paddingWithAppBarHeight=EdgeInsets.only(
      top: TSizes.appBarHeight,
      left: TSizes.defaultSpace,
      bottom: TSizes.defaultSpace,
      right: TSizes.defaultSpace
  );
}