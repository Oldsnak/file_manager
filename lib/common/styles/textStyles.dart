import 'package:flutter/material.dart';

class textStyles{
  static CustomText({required String text, double? height, Color? color, FontWeight? fontWeight,String? font="Inknut Antiqua"}){
    return Text(text, style: TextStyle(fontSize: height??14.0, color: color??Color(0xFFFFFFFF), fontWeight: fontWeight, fontFamily: font));
  }
}