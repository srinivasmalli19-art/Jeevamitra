import 'package:flutter/material.dart';

class AppColors {
  // Brand greens
  static const Color primary = Color(0xFF1B6B3A);
  static const Color primaryLight = Color(0xFF2E8B57);
  static const Color primaryDark = Color(0xFF0D4A25);
  static const Color primaryContainer = Color(0xFFD4EDDA);

  // Brand ambers (harvest/earth)
  static const Color secondary = Color(0xFFE07B39);
  static const Color secondaryLight = Color(0xFFFFB347);
  static const Color secondaryDark = Color(0xFFB85C20);
  static const Color secondaryContainer = Color(0xFFFFF0E0);

  // Semantic
  static const Color success = Color(0xFF27AE60);
  static const Color successContainer = Color(0xFFD5F5E3);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningContainer = Color(0xFFFEF9E7);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorContainer = Color(0xFFFDEDEC);
  static const Color info = Color(0xFF2980B9);
  static const Color infoContainer = Color(0xFFD6EAF8);

  // Emergency
  static const Color emergency = Color(0xFFD32F2F);
  static const Color emergencyLight = Color(0xFFFF5252);

  // Neutral surfaces
  static const Color background = Color(0xFFF7F7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F0);
  static const Color outline = Color(0xFFDDE1DD);
  static const Color divider = Color(0xFFE8EDE8);

  // Text
  static const Color textPrimary = Color(0xFF1A2B1A);
  static const Color textSecondary = Color(0xFF5A6B5A);
  static const Color textDisabled = Color(0xFFABBAAB);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE8EDE8);
  static const Color shimmerHighlight = Color(0xFFF5F8F5);

  // Shadow
  static const Color shadowLight = Color(0x0A1A2B1A);
  static const Color shadowMedium = Color(0x161A2B1A);
  static const Color shadowDark = Color(0x261A2B1A);

  // Gradient stops
  static const List<Color> primaryGradient = [primaryLight, primaryDark];
  static const List<Color> earthGradient = [Color(0xFFE8F5E9), Color(0xFFFFF8E1)];
  static const List<Color> sunsetGradient = [secondaryLight, secondary];
}
