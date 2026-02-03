import 'package:flutter/material.dart';

class TColors {
  TColors._();

  // 🌿 App Basic Colors
  static const Color primary = Color(0xFF2AB39F);     // Premium medical teal
  static const Color secondary = Color(0xFFFFC857);   // Warm accent (appointment highlight)
  static const Color optional = Color(0xFF4C9EEB);    // Calm medical blue (optional accent)

  // 🖋️ Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);   // Dark bold text
  static const Color textSecondary = Color(0xFF5A5A5A); // Labels, subtitles
  static const Color textWhite = Color(0xFFFFFFFF);     // White text


  // 🌑 Dark Mode Placeholder (for later dark theme)
  static const Color light = Color(0xFFFDFDFB); // Soft white
  static const Color dark = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFF81E6D9);     // Teal glow
  static const Color darkSecondary = Color(0xFFFFD479);   // Softer amber
  static const Color darkOptional = Color(0xFF76B5FF);    // Soft blue


  // 🪴 Background Colors
  static const Color lightGradientBackgroundStart = Color(0xFFF9FAFB);
  static const Color lightGradientBackgroundEnd = Color(0xFFEDEDED);
  static const Color darkGradientBackgroundStart = Color(0xFF333333); // 0% stop
  static const Color darkGradientBackgroundEnd   = Color(0xFF222222); // 100% stop
  static const RadialGradient lightGradientBackground = RadialGradient(
    colors: [
      Color(0xFFF9FAFB), // start
      Color(0xFFEDEDED), // end
    ],
    center: Alignment.center,
    radius: 1.0,
  );
  static const RadialGradient darkGradientBackground = RadialGradient(
    colors: [
      Color(0xFF333333), // 0%
      Color(0xFF222222), // 100%
    ],
    center: Alignment.center,
    radius: 1.0,
  );

  // 🧺 Container Backgrounds
  static const Color lightContainer = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFE6F5F2);   // soft teal
  static const Color lightSecondaryContainer = Color(0xFFFFF3D6); // soft amber
  static const Color lightOptionalContainer = Color(0xFFE8F2FF);  // soft blue
  static const Color darkContainer = Color(0xFF2B2B2B);
  static const Color darkPrimaryContainer = Color(0xFF1F3A37);     // teal overlay
  static const Color darkSecondaryContainer = Color(0xFF3A2F17);   // amber overlay
  static const Color darkOptionalContainer = Color(0xFF1A2C45);    // blue overlay


  // 🔘 Button Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonDisabled = Color(0xFFBFBFBF); // greyed out


  // 📏 Border Colors
  static const Color borderPrimary = Color(0xFF2AB39F);  // teal border
  static const Color borderSecondary = Color(0xFFFFC857);

  // ⚠️ Status Colors
  static const Color error = Color(0xFFE85050);
  static const Color success = Color(0xFF3EBB78);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);


  // ⚫ Neutral Shades
  static const Color black = Color(0xFF1A1A1A);
  static const Color darkerGrey = Color(0xFF3D3D3D);
  static const Color darkGrey = Color(0xFF707070);
  static const Color grey = Color(0xFFDADADA);
  static const Color softGrey = Color(0xFFF1F3F2);
  static const Color lightGrey = Color(0xFFFAFAFA);
  static const Color white = Color(0xFFFFFFFF);

}
