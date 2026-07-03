import 'package:flutter/cupertino.dart';

class AppTheme {
  static const Color canvasDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF151515);
  static const Color surfaceSecondaryDark = Color(0xFF242424);
  static const Color surfaceElevated = Color(0xFF30302E);

  static const Color iosBlue = Color(0xFF0A84FF);
  static const Color iosIndigo = Color(0xFF5E5CE6);
  static const Color iosGold = Color(0xFFFF9F0A);
  static const Color iosPink = Color(0xFFFF2D55);
  static const Color iosOrange = Color(0xFFFF6B1A);
  static const Color iosLight = Color(0xFFFFFFFF);
  static const Color iosRed = Color(0xFFFF453A);
  static const Color iosGreen = Color(0xFF30D158);
  static const Color iosGray = Color(0xFF8E8E93);
  static const Color iosBorderDark = Color(0xFF38383A);

  static const double radiusXl = 32;
  static const double radiusLg = 24;
  static const double radiusMd = 16;
  static const double radiusPill = 999;

  static const BorderSide thinBorderSide = BorderSide(
    color: iosBorderDark,
    width: 0.5,
  );

  static const Border thinBorder = Border.fromBorderSide(thinBorderSide);

  static const CupertinoThemeData cupertinoTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: iosBlue,
    scaffoldBackgroundColor: canvasDark,
    barBackgroundColor: surfaceDark,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        color: iosLight,
        fontSize: 16,
        letterSpacing: 0,
      ),
      navTitleTextStyle: TextStyle(
        color: iosLight,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: iosLight,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      actionTextStyle: TextStyle(
        color: iosBlue,
        fontSize: 17,
        letterSpacing: 0,
      ),
      tabLabelTextStyle: TextStyle(
        fontSize: 11,
        letterSpacing: 0,
      ),
    ),
  );

  static TextStyle displayLg({Color color = iosLight}) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headlineMd({Color color = iosLight}) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle titleSm({Color color = iosLight}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle bodyMd({Color color = iosLight}) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle bodySm({Color color = iosLight}) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle labelSm({Color color = iosLight}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle labelXs({Color color = iosLight}) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );
}
