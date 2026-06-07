import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../widgets/common/jm_badge.dart';
import '../../../widgets/common/jm_button.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';

class LandDetailScreen extends ConsumerWidget {
  final String farmId;
  const LandDetailScreen({super.key, required this.farmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmDetailProvider(farmId));

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
            body: const Center(child: Text('Land not found')),
          );
        }
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero image + app bar
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
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          ),
                        )
                      : _imagePlaceholder(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Edit',
                    onPressed: () => context.push(RouteConstants.farmerEditLandPath(farmId)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: AppColors.error),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
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
                        children: [
                          Expanded(
                            child: Text(farm.title,
                                style: Theme.of(context).textTheme.headlineSmall),
                          ),
                          JmBadge(
                            label: farm.isAvailable ? 'Available' : 'Unavailable',
                            variant: farm.isAvailable ? JmBadgeVariant.success : JmBadgeVariant.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${farm.village}, ${farm.district}, ${farm.state}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Stats row
                      Row(
                        children: [
                          _StatChip(icon: Icons.landscape_rounded,
                              label: '${farm.areaInAcres.toStringAsFixed(1)} ac'),
                          const SizedBox(width: AppSpacing.sm),
                          _StatChip(icon: Icons.currency_rupee_rounded,
                              label: '₹${farm.pricePerDayPerAnimal.toStringAsFixed(0)}/day/animal'),
                          const SizedBox(width: AppSpacing.sm),
                          _StatChip(icon: Icons.groups_rounded,
                              label: '${farm.maxAnimals} max'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Description
                      if (farm.description.isNotEmpty) ...[
                        Text('About', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(farm.description, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      // Fodder types
                      if (farm.fodderTypes.isNotEmpty) ...[
                        Text('Fodder Available', style: Theme.of(context).textTheme.titleMedium),
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
                      Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _AmenityChip(icon: Icons.water_drop_rounded,
                              label: 'Water', active: farm.hasWater),
                          _AmenityChip(icon: Icons.park_rounded,
                              label: 'Shade', active: farm.hasShade),
                          _AmenityChip(icon: Icons.fence_rounded,
                              label: 'Fencing', active: farm.hasFencing),
                          _AmenityChip(icon: Icons.medical_services_rounded,
                              label: 'Vet Nearby', active: farm.hasVetNearby),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Availability toggle
                      Card(
                        elevation: 0,
                        color: AppColors.surfaceVariant,
                        child: SwitchListTile(
                          title: const Text('Land Available for Grazing'),
                          subtitle: Text(farm.isAvailable
                              ? 'Shepherds can book this land'
                              : 'Hidden from shepherd search'),
                          value: farm.isAvailable,
                          onChanged: (v) => ref
                              .read(addFarmProvider.notifier)
                              .toggleAvailability(farm.id, v),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => context.push(
                            RouteConstants.farmerLandAvailabilityPath(farmId)),
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Manage Availability Calendar'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // GPS coords (for farmers to verify)
                      Text('Coordinates',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textDisabled)),
                      const SizedBox(height: 2),
                      Text('${farm.lat.toStringAsFixed(6)}, ${farm.lng.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textDisabled)),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.xl),
            child: JmButton(
              label: 'Edit Land Details',
              leadingIcon: Icons.edit_rounded,
              onPressed: () => context.push(RouteConstants.farmerEditLandPath(farmId)),
            ),
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder() => Container(
    color: AppColors.surfaceVariant,
    child: const Center(
      child: Icon(Icons.landscape_rounded, size: 80, color: AppColors.textDisabled),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Land?'),
        content: const Text(
            'This will permanently remove your land listing. Existing bookings are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref.read(addFarmProvider.notifier).deleteFarm(farmId);
    if (!context.mounted) return;
    if (ok) {
      context.go(RouteConstants.farmerLands);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed. Please try again.')),
      );
    }
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _AmenityChip({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon,
          size: 16, color: active ? AppColors.primary : AppColors.textDisabled),
      label: Text(label),
      backgroundColor: active ? AppColors.primaryContainer : AppColors.surfaceVariant,
      side: BorderSide(color: active ? AppColors.primary : AppColors.outline, width: 0.5),
      labelStyle: TextStyle(
          color: active ? AppColors.primary : AppColors.textDisabled, fontSize: 12),
    );
  }
}
