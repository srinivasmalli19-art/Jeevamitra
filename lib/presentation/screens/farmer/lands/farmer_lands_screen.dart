import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/firebase_error_translator.dart';
import '../../../../data/models/farm_model.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../widgets/common/cached_farm_image.dart';
import '../../../widgets/common/jm_badge.dart';
import '../../../widgets/common/jm_empty_state.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/common/responsive_center.dart';
import '../../../widgets/common/standard_app_bar.dart';

class FarmerLandsScreen extends ConsumerWidget {
  const FarmerLandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(myFarmsProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: StandardAppBar(
        title: loc.myLands,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(RouteConstants.farmerAddLand),
            tooltip: loc.addLand,
          ),
        ],
      ),
      body: farmsAsync.when(
        loading: () => const JmShimmerList(count: 3, cardHeight: 320),
        error: (e, _) => JmErrorState(
          message: friendlyFirebaseMessage(e),
          onRetry: () => ref.invalidate(myFarmsProvider),
        ),
        data: (farms) => farms.isEmpty
            ? JmEmptyState(
                icon: Icons.landscape_rounded,
                title: loc.noLandsYetTitle,
                subtitle: loc.noLandsYetSubtitle,
                buttonLabel: loc.addLand,
                onButtonTap: () => context.push(RouteConstants.farmerAddLand),
              )
            : ResponsiveCenter(
                child: ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: farms.length,
                  separatorBuilder: (_, i) =>
                      const SizedBox(height: AppSpacing.base),
                  itemBuilder: (_, i) => _FarmCard(farm: farms[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.farmerAddLand),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: Text(loc.addLand,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _FarmCard extends ConsumerWidget {
  final FarmModel farm;
  const _FarmCard({required this.farm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onTap: () => context.push(RouteConstants.landDetail(farm.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header with a status badge overlay, matching
            // NearbyLandCard's discovery-card presentation.
            Stack(
              children: [
                farm.imageUrls.isNotEmpty
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
              ],
            ),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(farm.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      _AvailabilitySwitch(farm: farm),
                    ],
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push(RouteConstants.landDetail(farm.id)),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(loc.viewDetailsBtn),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
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

class _AvailabilitySwitch extends ConsumerWidget {
  final FarmModel farm;
  const _AvailabilitySwitch({required this.farm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Switch(
      value: farm.isAvailable,
      onChanged: (v) async {
        final error =
            await ref.read(addFarmProvider.notifier).toggleAvailability(farm.id, v);
        if (error == null || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyFirebaseMessage(error)),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }
}
