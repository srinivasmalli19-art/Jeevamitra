import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/firebase_error_translator.dart';
import '../../../../data/models/farm_model.dart';
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

    return Scaffold(
      appBar: StandardAppBar(
        title: 'My Lands',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(RouteConstants.farmerAddLand),
            tooltip: 'Add Land',
          ),
        ],
      ),
      body: farmsAsync.when(
        loading: () => const JmShimmerList(count: 3, cardHeight: 140),
        error: (e, _) => JmErrorState(
          message: friendlyFirebaseMessage(e),
          onRetry: () => ref.invalidate(myFarmsProvider),
        ),
        data: (farms) => farms.isEmpty
            ? JmEmptyState(
                icon: Icons.landscape_rounded,
                title: 'No Lands Yet',
                subtitle:
                    'Add your farmland to start receiving bookings from shepherds.',
                buttonLabel: '+ Add Land',
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
        label: const Text('Add Land',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _FarmCard extends ConsumerWidget {
  final FarmModel farm;
  const _FarmCard({required this.farm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
        side: const BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: () => context.push(RouteConstants.landDetail(farm.id)),
        borderRadius: AppSpacing.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg)),
              child: farm.imageUrls.isNotEmpty
                  ? CachedFarmImage(
                      url: farm.imageUrls.first,
                      height: 140,
                      width: double.infinity,
                    )
                  : _placeholder(),
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
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(farm.village,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.landscape_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${farm.areaInAcres.toStringAsFixed(1)} acres',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        '₹${farm.pricePerDayPerAnimal.toStringAsFixed(0)}/day/animal',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                      const Spacer(),
                      JmBadge(
                        label: farm.isAvailable ? 'Available' : 'Unavailable',
                        variant: farm.isAvailable
                            ? JmBadgeVariant.success
                            : JmBadgeVariant.neutral,
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

  Widget _placeholder() => Container(
        height: 140,
        width: double.infinity,
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.landscape_rounded,
            size: 48, color: AppColors.textDisabled),
      );
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
