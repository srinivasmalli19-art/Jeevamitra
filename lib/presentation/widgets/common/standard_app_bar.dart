import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Consistent AppBar used across every non-hero screen: same height,
/// typography, icon color, and contrast. Wraps [AppBar] rather than
/// reimplementing it, so it keeps standard `Scaffold`/`SafeArea` behavior
/// for free.
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  const StandardAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      toolbarHeight: AppSpacing.appBarHeight,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textOnPrimary, size: 24),
      actionsIconTheme:
          const IconThemeData(color: AppColors.textOnPrimary, size: 24),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        AppSpacing.appBarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
