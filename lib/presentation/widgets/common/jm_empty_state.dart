import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'jm_button.dart';

class JmEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;
  final Color? iconColor;

  const JmEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor ?? AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: AppSpacing.xl),
              JmButton(
                label: buttonLabel!,
                onPressed: onButtonTap,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
