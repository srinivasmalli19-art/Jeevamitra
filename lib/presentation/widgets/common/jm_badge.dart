import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum JmBadgeVariant { primary, success, warning, error, info, neutral }

class JmBadge extends StatelessWidget {
  final String label;
  final JmBadgeVariant variant;
  final IconData? icon;
  final bool small;

  const JmBadge({
    super.key,
    required this.label,
    this.variant = JmBadgeVariant.primary,
    this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      JmBadgeVariant.primary => (AppColors.primaryContainer, AppColors.primaryDark),
      JmBadgeVariant.success => (AppColors.successContainer, AppColors.success),
      JmBadgeVariant.warning => (AppColors.warningContainer, AppColors.warning),
      JmBadgeVariant.error => (AppColors.errorContainer, AppColors.error),
      JmBadgeVariant.info => (AppColors.infoContainer, AppColors.info),
      JmBadgeVariant.neutral => (AppColors.surfaceVariant, AppColors.textSecondary),
    };

    final fontSize = small ? 10.0 : 12.0;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
