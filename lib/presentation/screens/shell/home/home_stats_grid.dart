import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/geo_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/alerts/disease_alert_providers.dart';
import '../../../providers/booking/booking_providers.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vet/vet_providers.dart';
import '../../../widgets/common/dashboard_stat_card.dart';

/// The prototype's 2x2 cross-domain summary — Nearby lands available,
/// Active bookings, Vets nearby, Active high-severity alerts. Distinct
/// from Sprint 5's MyLandsSection (owned-land count only): every number
/// here comes from the same existing providers the individual content
/// sections already use — no new repository queries, no fabricated data.
///
/// "Active bookings" = bookings (either as land owner or as booker) not
/// yet completed or cancelled — i.e. pending/confirmed/active — combined
/// across both existing booking providers, not gated by role/profileType
/// (Universal Access: shown whenever the data exists).
/// "Active high-severity alerts" = nearby alerts (already isActive-filtered
/// server-side by watchNearby) whose severity is 'critical' or 'high'.
class HomeStatsGrid extends ConsumerWidget {
  const HomeStatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final location = ref.watch(locationProvider).valueOrNull;

    final farmerBookingsAsync = ref.watch(farmerBookingsProvider);
    final shepherdBookingsAsync = ref.watch(shepherdBookingsProvider);

    // The three "nearby" stats all need a location; while it's unresolved,
    // show the loading treatment for the whole grid rather than a
    // partially-populated one.
    if (location == null) {
      return const _StatsGridShimmer();
    }

    final nearbyFarmsAsync = ref.watch(nearbyFarmsProvider((
      lat: location.lat,
      lng: location.lng,
      radiusKm: GeoConstants.radiusNearby,
    )));
    final nearbyVetsAsync = ref.watch(nearbyVetsProvider((
      lat: location.lat,
      lng: location.lng,
      radiusKm: GeoConstants.radiusNearby,
    )));
    final nearbyAlertsAsync = ref.watch(nearbyAlertsProvider((
      lat: location.lat,
      lng: location.lng,
      radiusKm: GeoConstants.radiusNearby,
    )));

    final stillLoading = farmerBookingsAsync.isLoading ||
        shepherdBookingsAsync.isLoading ||
        nearbyFarmsAsync.isLoading ||
        nearbyVetsAsync.isLoading ||
        nearbyAlertsAsync.isLoading;
    if (stillLoading) {
      return const _StatsGridShimmer();
    }

    final availableLandsCount = (nearbyFarmsAsync.valueOrNull ?? [])
        .where((f) => f.isAvailable)
        .length;

    const openStatuses = {'pending', 'confirmed', 'active'};
    final activeBookingsCount = (farmerBookingsAsync.valueOrNull ?? [])
            .where((b) => openStatuses.contains(b.status))
            .length +
        (shepherdBookingsAsync.valueOrNull ?? [])
            .where((b) => openStatuses.contains(b.status))
            .length;

    final vetsNearbyCount = (nearbyVetsAsync.valueOrNull ?? []).length;

    final highSeverityAlertsCount = (nearbyAlertsAsync.valueOrNull ?? [])
        .where((a) => a.severity == 'critical' || a.severity == 'high')
        .length;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DashboardStatCard(
                label: loc.nearbyLandsAvailableLabel,
                value: '$availableLandsCount',
                color: AppColors.primary,
                style: DashboardStatCardStyle.filled,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DashboardStatCard(
                label: loc.activeBookingsLabel,
                value: '$activeBookingsCount',
                color: AppColors.primary,
                style: DashboardStatCardStyle.filled,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DashboardStatCard(
                label: loc.nearbyVets,
                value: '$vetsNearbyCount',
                color: AppColors.primary,
                style: DashboardStatCardStyle.outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DashboardStatCard(
                label: loc.activeHighSeverityAlertsLabel,
                value: '$highSeverityAlertsCount',
                color: AppColors.emergency,
                style: DashboardStatCardStyle.filled,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsGridShimmer extends StatelessWidget {
  const _StatsGridShimmer();

  @override
  Widget build(BuildContext context) {
    Widget cell() => Container(
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: AppSpacing.cardRadius,
          ),
        );

    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        children: [
          Row(children: [
            Expanded(child: cell()),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: cell()),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: cell()),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: cell()),
          ]),
        ],
      ),
    );
  }
}
