import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // MIANE Core Design System Tokens
  static const Color canvasDark = Color(0xFF05101E);       // Deep Abyss
  static const Color surfaceDark = Color(0xFF0D2C54);      // Heritage Navy
  static const Color surfaceSecondaryDark = Color(0xFF1A3D6C); // Soft Navy/Azure transition
  
  static const Color iosBlue = Color(0xFF4A90E2);          // Luminous Azure
  static const Color iosIndigo = Color(0xFF5856D6);
  static const Color iosGold = Color(0xFFF4BD64);          // Sand Gold
  static const Color iosLight = Color(0xFFF8F9FA);         // White Smoke
  static const Color iosRed = Color(0xFFFF453A);
  static const Color iosGreen = Color(0xFF30D158);
  static const Color iosGray = Color(0xFF8E8E93);
  static const Color iosBorderDark = Color(0xFF1A3D6C);    // Border color matching surface transition

  // Border radius tokens
  static const double radiusLg = 32.0;                     // Global rounded corner radius
  static const double radiusMd = 16.0;
  static const double radiusPill = 99.0;


  // Thin borders
  static final BorderSide thinBorderSide = BorderSide(
    color: iosBorderDark,
    width: 0.5,
  );

  static final Border thinBorder = Border.all(
    color: iosBorderDark,
    width: 0.5,
  );

  // Text Styles using Inter & Be Vietnam Pro (Apple SF alternatives)
  static TextStyle displayLg({Color color = iosLight}) => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle headlineMd({Color color = iosLight}) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle titleSm({Color color = iosLight}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle bodyMd({Color color = iosLight}) => GoogleFonts.beVietnamPro(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle bodySm({Color color = iosLight}) => GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle labelSm({Color color = iosLight}) => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle labelXs({Color color = iosLight}) => GoogleFonts.beVietnamPro(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
