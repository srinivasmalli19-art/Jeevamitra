import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/firebase_error_translator.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../common/jm_button.dart';

/// Card-styled error state that always shows a translated, user-friendly
/// message — takes the raw error object and runs it through
/// [friendlyFirebaseMessage] internally, so callers never need to (and
/// can never accidentally) surface a raw `error.toString()` again.
class RetryCard extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const RetryCard({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          boxShadow: AppShadows.md,
          border: Border.all(color: AppColors.errorContainer),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              loc.errorMsg,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              friendlyFirebaseMessage(error),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              JmButton(
                label: loc.retryBtn,
                onPressed: onRetry,
                fullWidth: false,
                leadingIcon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
