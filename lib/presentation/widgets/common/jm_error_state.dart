import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'jm_button.dart';

class JmErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isNetwork;

  const JmErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.isNetwork = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              isNetwork ? 'No Internet' : 'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              JmButton(
                label: 'Try Again',
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
