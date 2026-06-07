import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> card = md;
  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 16,
      offset: Offset(0, -2),
    ),
  ];
  static const List<BoxShadow> fab = lg;
}
