import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class JmLoading extends StatelessWidget {
  final String? message;
  const JmLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.base),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Shimmer placeholder for a card-shaped item
class JmShimmerCard extends StatelessWidget {
  final double height;
  final double? width;

  const JmShimmerCard({super.key, this.height = 120, this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: AppSpacing.cardRadius,
        ),
      ),
    );
  }
}

/// Shimmer list of N card placeholders
class JmShimmerList extends StatelessWidget {
  final int count;
  final double cardHeight;

  const JmShimmerList({super.key, this.count = 4, this.cardHeight = 120});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: count,
      separatorBuilder: (_, i) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => JmShimmerCard(height: cardHeight),
    );
  }
}
