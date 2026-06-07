import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double section = 64;

  // Edge insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: base, vertical: base);
  static const EdgeInsets screenHPadding = EdgeInsets.symmetric(horizontal: base);
  static const EdgeInsets cardPadding = EdgeInsets.all(base);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: base, vertical: md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xl, vertical: md);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: base, vertical: 14);

  // Border radii
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  static BorderRadius get cardRadius => BorderRadius.circular(radiusLg);
  static BorderRadius get buttonRadius => BorderRadius.circular(radiusMd);
  static BorderRadius get inputRadius => BorderRadius.circular(radiusMd);
  static BorderRadius get chipRadius => BorderRadius.circular(radiusFull);
  static BorderRadius get bottomSheetRadius => const BorderRadius.vertical(top: Radius.circular(radiusXl));

  // Standard heights
  static const double buttonHeight = 52;
  static const double buttonHeightSm = 40;
  static const double inputHeight = 56;
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 64;
  static const double fabSize = 56;
  static const double avatarSm = 36;
  static const double avatarMd = 48;
  static const double avatarLg = 72;
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
}
