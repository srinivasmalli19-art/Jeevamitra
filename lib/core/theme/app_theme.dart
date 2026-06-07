import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.secondaryDark,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.outline,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.error,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textOnPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary, size: 24),
        actionsIconTheme: const IconThemeData(color: AppColors.textOnPrimary, size: 24),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.outline,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: AppSpacing.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.outline, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDisabled),
        errorStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.error),
        floatingLabelStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.primary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
        margin: EdgeInsets.zero,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.surfaceVariant,
        labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary,
        ),
        padding: AppSpacing.chipPadding,
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.chipRadius),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textDisabled,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textDisabled, size: 24);
        }),
        elevation: 8,
        height: AppSpacing.bottomNavHeight,
        shadowColor: AppColors.shadowMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.bottomSheetRadius),
        elevation: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14, color: AppColors.textSecondary,
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.xs,
        ),
        iconColor: AppColors.textSecondary,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 13, color: AppColors.textSecondary,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emergency,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryContainer,
        circularTrackColor: AppColors.primaryContainer,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primaryContainer
              : AppColors.outline;
        }),
      ),
    );
  }
}
