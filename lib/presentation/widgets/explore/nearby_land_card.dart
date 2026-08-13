import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../core/utils/url_launch_helper.dart';
import '../../../data/models/farm_model.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../common/cached_farm_image.dart';
import '../common/jm_badge.dart';

/// Premium discovery card for a nearby farm: image, title, location,
/// distance, area, availability, price, and two actions — "View Details"
/// (navigates into Land Detail) and "Navigate" (opens the device's maps
/// app for turn-by-turn directions). Coordinates are used only to build
/// the maps deep link and compute [distanceKm] upstream — never rendered
/// as text here.
class NearbyLandCard extends StatelessWidget {
  final FarmModel farm;
  final double distanceKm;
  final VoidCallback onViewDetails;

  const NearbyLandCard({
    super.key,
    required this.farm,
    required this.distanceKm,
    required this.onViewDetails,
  });

  Future<void> _navigate(BuildContext context, AppLocalizations loc) => launchExternalUrl(
        context,
        mapsSearchUri(farm.lat, farm.lng),
        mode: LaunchMode.externalApplication,
        failureMessage: loc.couldNotOpenMapsMsg,
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppShadows.md,
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'land-image-${farm.id}',
                  child: farm.imageUrls.isNotEmpty
                      ? CachedFarmImage(
                          url: farm.imageUrls.first,
                          height: 160,
                          width: double.infinity,
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.landscape_rounded,
                              size: 56, color: AppColors.textDisabled),
                        ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: JmBadge(
                    label: farm.isAvailable ? loc.availableNow : loc.notAvailable,
                    variant: farm.isAvailable
                        ? JmBadgeVariant.success
                        : JmBadgeVariant.neutral,
                    small: true,
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          formatDistanceAway(distanceKm, loc),
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${farm.village}, ${farm.district}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.landscape_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(loc.acres(farm.areaInAcres.toStringAsFixed(1)),
                          style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      Text(
                        '₹${farm.pricePerDayPerAnimal.toStringAsFixed(0)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                      Text(loc.perDayAnimalSuffix,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _navigate(context, loc),
                          icon: const Icon(Icons.directions_rounded, size: 16),
                          label: Text(loc.navigateBtn),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onViewDetails,
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: Text(loc.viewDetailsBtn),
                          style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
