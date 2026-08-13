import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Content-shaped shimmer placeholder — mimics an alert/tip card's real
/// layout (leading icon circle + title line + subtitle line) rather than
/// a single featureless shimmer rectangle, so the loading state doesn't
/// visually jump when real content arrives.
class LoadingSkeleton extends StatelessWidget {
  final int count;

  const LoadingSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    // Deliberately a normal (not shrink-wrapped/non-scrolling) ListView:
    // this widget is meant to fill a bounded parent (typically an
    // Expanded), and disabling scroll there would clip skeleton cards on
    // shorter screens with no way to reveal them.
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.separated(
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 160, color: Colors.white),
                const SizedBox(height: AppSpacing.sm),
                Container(height: 11, width: double.infinity, color: Colors.white),
                const SizedBox(height: AppSpacing.xs),
                Container(height: 11, width: 120, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
