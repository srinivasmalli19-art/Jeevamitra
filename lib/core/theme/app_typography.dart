import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme get textTheme {
    return TextTheme(
      // Display — hero banners
      displayLarge: GoogleFonts.poppins(
        fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3,
      ),
      // Headline — screen titles
      headlineLarge: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4,
      ),
      // Title — cards, sections
      titleLarge: GoogleFonts.poppins(
        fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.5,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.5,
      ),
      // Body
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.6,
      ),
      // Label — buttons, chips, tags
      labelLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary, height: 1.4,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4,
      ),
    );
  }

  // Telugu/Hindi override — system font renders better than Poppins for Indic scripts
  static TextStyle indicBody(double size) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  /// Serif display style — added for the prototype's headline treatment
  /// (e.g. the Home greeting "Namaste, Ravi"). Deliberately a separate
  /// named method rather than repurposing `textTheme.displayLarge`
  /// (Poppins), so existing callers of the Material text theme are
  /// unaffected; Poppins remains the app's primary/default face
  /// everywhere else per Sprint 1. Named distinctly from
  /// `textTheme.displayLarge` to avoid confusion between the two.
  static TextStyle serifDisplay({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
  }) => GoogleFonts.merriweather(fontSize: size, fontWeight: weight, color: color, height: 1.25);
}
