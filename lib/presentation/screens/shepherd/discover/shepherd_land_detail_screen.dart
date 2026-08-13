import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/distance_formatter.dart';
import '../../../../core/utils/firebase_error_translator.dart';
import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../core/utils/url_launch_helper.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../widgets/common/cached_farm_image.dart';
import '../../../widgets/common/full_screen_photo_viewer.dart';
import '../../../widgets/common/jm_badge.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';

class ShepherdLandDetailScreen extends ConsumerWidget {
  final String farmId;
  const ShepherdLandDetailScreen({super.key, required this.farmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final farmAsync = ref.watch(farmDetailProvider(farmId));
    final locAsync = ref.watch(locationProvider);

    return farmAsync.when(
      loading: () => const Scaffold(body: Center(child: JmLoading())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(loc.landDetailsTitle)),
        body: JmErrorState(
          message: friendlyFirebaseMessage(e),
          onRetry: () => ref.invalidate(farmDetailProvider(farmId)),
        ),
      ),
      data: (farm) {
        if (farm == null) {
          return Scaffold(
            appBar: AppBar(title: Text(loc.landDetailsTitle)),
            body: Center(child: Text(loc.landNoLongerAvailableMsg)),
          );
        }

        // Distance from shepherd's current location — GeoHashHelper.distanceKm,
        // the same Haversine formula the repository uses to filter/sort
        // nearby results, so a card's displayed distance can never disagree
        // with the one shown here for the same farm.
        String? distLabel;
        final userLoc = locAsync.valueOrNull;
        if (userLoc != null) {
          final km = GeoHashHelper.distanceKm(userLoc.lat, userLoc.lng, farm.lat, farm.lng);
          distLabel = formatDistanceAway(km, loc);
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: farm.imageUrls.isNotEmpty
                      ? PageView.builder(
                          itemCount: farm.imageUrls.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => showFullScreenPhotoViewer(
                              context,
                              urls: farm.imageUrls,
                              initialIndex: i,
                            ),
                            // Only the first image shares the discovery
                            // card's Hero tag — Hero requires exactly one
                            // matching pair per navigation, and the card
                            // only ever shows imageUrls.first.
                            child: i == 0
                                ? Hero(
                                    tag: 'land-image-${farm.id}',
                                    child: CachedFarmImage(url: farm.imageUrls[i]),
                                  )
                                : CachedFarmImage(url: farm.imageUrls[i]),
                          ),
                        )
                      : _placeholder(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.base),
                      // Title + availability
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(farm.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                if (distLabel != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.near_me_rounded,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(distLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          JmBadge(
                            label: farm.isAvailable ? loc.availableNow : loc.notAvailable,
                            variant: farm.isAvailable
                                ? JmBadgeVariant.success
                                : JmBadgeVariant.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${farm.village}, ${farm.district}, ${farm.state}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Owner info
                      if (farm.ownerName.isNotEmpty) ...[
                        _InfoRow(
                          icon: Icons.person_rounded,
                          label: loc.farmerLabel,
                          value: farm.ownerName,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      // Key stats
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.landscape_rounded,
                              label: loc.areaLabel,
                              value: loc.acres(farm.areaInAcres.toStringAsFixed(1)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.groups_rounded,
                              label: loc.maxAnimalsLabel,
                              value: '${farm.maxAnimals}',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.currency_rupee_rounded,
                              label: loc.perDayLabel,
                              value:
                                  '₹${farm.pricePerDayPerAnimal.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Description
                      if (farm.description.isNotEmpty) ...[
                        Text(loc.aboutLandTitle,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(farm.description,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      // Fodder types
                      if (farm.fodderTypes.isNotEmpty) ...[
                        Text(loc.fodderTypes,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: farm.fodderTypes
                              .map((f) => Chip(
                                    label: Text(_fodderLabel(f)),
                                    backgroundColor: AppColors.primaryContainer,
                                    side: BorderSide.none,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      // Amenities
                      Text(loc.amenities,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _AmenityChip(
                              icon: Icons.water_drop_rounded,
                              label: loc.water,
                              active: farm.hasWater),
                          _AmenityChip(
                              icon: Icons.park_rounded,
                              label: loc.shade,
                              active: farm.hasShade),
                          _AmenityChip(
                              icon: Icons.fence_rounded,
                              label: loc.fencing,
                              active: farm.hasFencing),
                          _AmenityChip(
                              icon: Icons.medical_services_rounded,
                              label: loc.vetNearby,
                              active: farm.hasVetNearby),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // Pricing note
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppSpacing.cardRadius,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.primary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                '₹${farm.pricePerDayPerAnimal.toStringAsFixed(0)}'
                                '${loc.perAnimalPerDaySuffix}${loc.finalAmountNoteMsg}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigate(context, farm.lat, farm.lng, loc),
                    icon: const Icon(Icons.directions_rounded),
                    label: Text(loc.navigateBtn),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.buttonHeight),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: farm.isAvailable
                      ? FilledButton.icon(
                          onPressed: () =>
                              context.push(RouteConstants.shepherdBook(farmId)),
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Text(loc.bookThisLandBtn),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, AppSpacing.buttonHeight),
                            backgroundColor: AppColors.secondary,
                          ),
                        )
                      : OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, AppSpacing.buttonHeight),
                          ),
                          child: Text(loc.notAvailableForBookingMsg),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigate(
          BuildContext context, double lat, double lng, AppLocalizations loc) =>
      launchExternalUrl(
        context,
        mapsSearchUri(lat, lng),
        mode: LaunchMode.externalApplication,
        failureMessage: loc.couldNotOpenMapsMsg,
      );

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.landscape_rounded,
              size: 80, color: AppColors.textDisabled),
        ),
      );

  String _fodderLabel(String type) {
    const map = {
      'grass': '🌿 Grass',
      'sorghum': '🌾 Sorghum',
      'maize': '🌽 Maize',
      'cotton': '🪴 Cotton',
      'groundnut': '🥜 Groundnut',
      'paddy': '🌾 Paddy',
      'sugarcane': '🎋 Sugarcane',
    };
    return map[type] ?? type;
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: AppSpacing.iconMd),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _AmenityChip(
      {required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon,
          size: 16,
          color: active ? AppColors.primary : AppColors.textDisabled),
      label: Text(label),
      backgroundColor:
          active ? AppColors.primaryContainer : AppColors.surfaceVariant,
      side: BorderSide(
          color: active ? AppColors.primary : AppColors.outline, width: 0.5),
      labelStyle: TextStyle(
          color: active ? AppColors.primary : AppColors.textDisabled,
          fontSize: 12),
    );
  }
}
