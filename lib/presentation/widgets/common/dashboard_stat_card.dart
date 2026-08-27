import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Visual treatment for [DashboardStatCard]. [tinted] is the original,
/// default look (cream card, colored icon chip) used by every caller
/// before Sprint 6A — unchanged, so no existing call site needs to change.
/// [filled] and [outlined] were added for the Home stats grid's prototype
/// treatment (solid-color cards for primary metrics, a light outlined card
/// for the neutral one) — generic variants, not hard-coded to any specific
/// stat's business meaning.
enum DashboardStatCardStyle { tinted, filled, outlined }

/// Statistic tile used on dashboard-style overview rows: a bold value and
/// a muted label, with an optional icon chip, an optional "needs
/// attention" badge dot, an optional tap target, and a [style] variant.
///
/// Sizes to its incoming constraints rather than forcing [Expanded] itself,
/// so callers can place it directly in a [Row] (wrap it in `Expanded`) or in
/// a width-aware [Wrap]/grid (wrap it in a fixed-width `SizedBox`).
class DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  // Nullable (was required) — the prototype's filled/outlined stats cards
  // show no icon at all, just value + label. Every existing caller still
  // passes icon explicitly, so this is not a breaking change for them.
  final IconData? icon;
  final Color color;
  final bool badge;
  final VoidCallback? onTap;
  final DashboardStatCardStyle style;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    required this.color,
    this.badge = false,
    this.onTap,
    this.style = DashboardStatCardStyle.tinted,
  });

  @override
  Widget build(BuildContext context) {
    final filled = style == DashboardStatCardStyle.filled;
    final outlined = style == DashboardStatCardStyle.outlined;

    final Color background =
        filled ? color : (outlined ? AppColors.surface : AppColors.surfaceCream);
    final Color valueColor = filled ? Colors.white : AppColors.textPrimary;
    final Color labelColor =
        filled ? Colors.white.withAlpha(225) : AppColors.textSecondary;
    final Border? border = filled
        ? null
        : Border.all(
            // Badge state keeps the caller's semantic accent (e.g. warning
            // amber for "needs attention"); outlined uses the card's own
            // accent color; the plain tinted resting state uses a soft
            // green-tinted line instead of plain grey.
            color: outlined
                ? color.withAlpha(140)
                : (badge ? color.withAlpha(140) : AppColors.primary.withAlpha(38)),
            width: (outlined || badge) ? 1.5 : 1,
          );

    return Material(
      color: background,
      borderRadius: AppSpacing.cardRadius,
      child: InkWell(
        borderRadius: AppSpacing.cardRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.base, horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppSpacing.cardRadius,
            boxShadow: AppShadows.sm,
            border: border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: filled ? Colors.white.withAlpha(46) : color.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: filled ? Colors.white : color, size: 18),
                    ),
                    if (badge)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.surface, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 11, color: labelColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
