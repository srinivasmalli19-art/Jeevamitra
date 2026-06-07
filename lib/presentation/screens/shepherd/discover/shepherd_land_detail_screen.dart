import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../widgets/common/jm_badge.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';

class ShepherdLandDetailScreen extends ConsumerWidget {
  final String farmId;
  const ShepherdLandDetailScreen({super.key, required this.farmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmDetailProvider(farmId));
    final locAsync = ref.watch(locationProvider);

    return farmAsync.when(
      loading: () => const Scaffold(body: Center(child: JmLoading())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Land Details')),
        body: JmErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(farmDetailProvider(farmId)),
        ),
      ),
      data: (farm) {
        if (farm == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Land Details')),
            body: const Center(child: Text('This land is no longer available.')),
          );
        }

        // Distance from shepherd's current location
        String? distLabel;
        final loc = locAsync.valueOrNull;
        if (loc != null) {
          final km = LocationService()
              .distanceBetween(loc.lat, loc.lng, farm.lat, farm.lng);
          distLabel =
              km < 1 ? '${(km * 1000).toInt()} m away' : '${km.toStringAsFixed(1)} km away';
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
                          itemBuilder: (_, i) => Image.network(
                            farm.imageUrls[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
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
                            label: farm.isAvailable ? 'Available' : 'Unavailable',
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
                          label: 'Farmer',
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
                              label: 'Area',
                              value: '${farm.areaInAcres.toStringAsFixed(1)} acres',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.groups_rounded,
                              label: 'Max Animals',
                              value: '${farm.maxAnimals}',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.currency_rupee_rounded,
                              label: 'Per Day',
                              value:
                                  '₹${farm.pricePerDayPerAnimal.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Description
                      if (farm.description.isNotEmpty) ...[
                        Text('About the Land',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(farm.description,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      // Fodder types
                      if (farm.fodderTypes.isNotEmpty) ...[
                        Text('Fodder Available',
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
                      Text('Amenities',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _AmenityChip(
                              icon: Icons.water_drop_rounded,
                              label: 'Water',
                              active: farm.hasWater),
                          _AmenityChip(
                              icon: Icons.park_rounded,
                              label: 'Shade',
                              active: farm.hasShade),
                          _AmenityChip(
                              icon: Icons.fence_rounded,
                              label: 'Fencing',
                              active: farm.hasFencing),
                          _AmenityChip(
                              icon: Icons.medical_services_rounded,
                              label: 'Vet Nearby',
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
                                '₹${farm.pricePerDayPerAnimal.toStringAsFixed(0)} per animal per day. '
                                'Final amount depends on herd size and number of days.',
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
          bottomNavigationBar: farm.isAvailable
              ? Padding(
                  padding: AppSpacing.screenPadding
                      .copyWith(bottom: AppSpacing.xl),
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push(RouteConstants.shepherdBook(farmId)),
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Book This Land'),
                    style: FilledButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, AppSpacing.buttonHeight),
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                )
              : Padding(
                  padding: AppSpacing.screenPadding
                      .copyWith(bottom: AppSpacing.xl),
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, AppSpacing.buttonHeight),
                    ),
                    child: const Text('Not Available for Booking'),
                  ),
                ),
        );
      },
    );
  }

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
