import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/farm_model.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../widgets/common/jm_empty_state.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';

// ─── Filter state ─────────────────────────────────────────────────────────────

class _FilterState {
  final double radiusKm;
  final List<String> fodderTypes;
  final bool onlyWater;
  final bool onlyShade;
  final bool onlyFencing;
  final double? maxPricePerDay;

  const _FilterState({
    this.radiusKm = 50,
    this.fodderTypes = const [],
    this.onlyWater = false,
    this.onlyShade = false,
    this.onlyFencing = false,
    this.maxPricePerDay,
  });

  _FilterState copyWith({
    double? radiusKm, List<String>? fodderTypes,
    bool? onlyWater, bool? onlyShade, bool? onlyFencing,
    double? maxPricePerDay, bool clearMaxPrice = false,
  }) => _FilterState(
    radiusKm: radiusKm ?? this.radiusKm,
    fodderTypes: fodderTypes ?? this.fodderTypes,
    onlyWater: onlyWater ?? this.onlyWater,
    onlyShade: onlyShade ?? this.onlyShade,
    onlyFencing: onlyFencing ?? this.onlyFencing,
    maxPricePerDay: clearMaxPrice ? null : (maxPricePerDay ?? this.maxPricePerDay),
  );

  bool get hasActiveFilters =>
      fodderTypes.isNotEmpty || onlyWater || onlyShade || onlyFencing || maxPricePerDay != null;

  List<FarmModel> apply(List<FarmModel> farms) {
    return farms.where((f) {
      if (fodderTypes.isNotEmpty && !fodderTypes.any((t) => f.fodderTypes.contains(t))) return false;
      if (onlyWater && !f.hasWater) return false;
      if (onlyShade && !f.hasShade) return false;
      if (onlyFencing && !f.hasFencing) return false;
      if (maxPricePerDay != null && f.pricePerDayPerAnimal > maxPricePerDay!) return false;
      return true;
    }).toList();
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ShepherdDiscoverScreen extends ConsumerStatefulWidget {
  const ShepherdDiscoverScreen({super.key});

  @override
  ConsumerState<ShepherdDiscoverScreen> createState() => _ShepherdDiscoverScreenState();
}

class _ShepherdDiscoverScreenState extends ConsumerState<ShepherdDiscoverScreen> {
  _FilterState _filter = const _FilterState();

  static const _radii = [10.0, 25.0, 50.0, 100.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = ref.read(locationProvider);
      if (!loc.hasValue || loc.valueOrNull == null) {
        ref.read(locationProvider.notifier).fetch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locAsync = ref.watch(locationProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Discover Lands'),
            floating: true,
            snap: true,
            actions: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Filters',
                    onPressed: () => _showFilterSheet(context),
                  ),
                  if (_filter.hasActiveFilters)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary, shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _RadiusBar(
                selected: _filter.radiusKm,
                radii: _radii,
                onSelect: (r) => setState(() => _filter = _filter.copyWith(radiusKm: r)),
              ),
            ),
          ),
          if (locAsync.isLoading)
            const SliverFillRemaining(child: Center(child: JmLoading()))
          else if (locAsync.hasError)
            SliverFillRemaining(
              child: JmErrorState(
                message: 'Could not get your location. Please enable GPS.',
                onRetry: () => ref.read(locationProvider.notifier).fetch(),
              ),
            )
          else if (locAsync.valueOrNull == null)
            SliverFillRemaining(
              child: _LocationPermissionView(
                onRequest: () => ref.read(locationProvider.notifier).fetch(),
              ),
            )
          else
            _FarmList(
              lat: locAsync.value!.lat,
              lng: locAsync.value!.lng,
              filter: _filter,
            ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        initial: _filter,
        onApply: (f) => setState(() => _filter = f),
      ),
    );
  }
}

// ─── Radius bar ───────────────────────────────────────────────────────────────

class _RadiusBar extends StatelessWidget {
  final double selected;
  final List<double> radii;
  final ValueChanged<double> onSelect;

  const _RadiusBar({required this.selected, required this.radii, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenHPadding,
        children: radii.map((r) {
          final active = r == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm, top: 8, bottom: 8),
            child: ChoiceChip(
              label: Text('${r.toInt()} km'),
              selected: active,
              onSelected: (_) => onSelect(r),
              selectedColor: AppColors.primaryContainer,
              labelStyle: TextStyle(
                color: active ? AppColors.primary : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Farm list ────────────────────────────────────────────────────────────────

class _FarmList extends ConsumerWidget {
  final double lat, lng;
  final _FilterState filter;

  const _FarmList({required this.lat, required this.lng, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(nearbyFarmsProvider((
      lat: lat,
      lng: lng,
      radiusKm: filter.radiusKm,
    )));

    return farmsAsync.when(
      loading: () => const SliverFillRemaining(
        child: JmShimmerList(count: 4, cardHeight: 200),
      ),
      error: (e, _) => SliverFillRemaining(
        child: JmErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(nearbyFarmsProvider),
          isNetwork: true,
        ),
      ),
      data: (all) {
        final farms = filter.apply(all);
        if (farms.isEmpty) {
          return SliverFillRemaining(
            child: JmEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No Lands Found',
              subtitle: filter.hasActiveFilters
                  ? 'Try removing some filters or increasing the radius.'
                  : 'No available grazing land within ${filter.radiusKm.toInt()} km.',
            ),
          );
        }
        return SliverPadding(
          padding: AppSpacing.screenPadding,
          sliver: SliverList.separated(
            itemCount: farms.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) =>
                _DiscoverCard(farm: farms[i], userLat: lat, userLng: lng),
          ),
        );
      },
    );
  }
}

// ─── Discover card ────────────────────────────────────────────────────────────

class _DiscoverCard extends StatelessWidget {
  final FarmModel farm;
  final double userLat, userLng;

  const _DiscoverCard(
      {required this.farm, required this.userLat, required this.userLng});

  @override
  Widget build(BuildContext context) {
    final distKm =
        LocationService().distanceBetween(userLat, userLng, farm.lat, farm.lng);
    final distLabel = distKm < 1
        ? '${(distKm * 1000).toInt()} m'
        : '${distKm.toStringAsFixed(1)} km';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
        side: const BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: () => context.push(RouteConstants.shepherdLand(farm.id)),
        borderRadius: AppSpacing.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg)),
              child: farm.imageUrls.isNotEmpty
                  ? Image.network(
                      farm.imageUrls.first,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
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
                      _DistanceBadge(label: distLabel),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text('${farm.village}, ${farm.district}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _AmenityDot(
                          icon: Icons.water_drop_rounded,
                          active: farm.hasWater,
                          tooltip: 'Water'),
                      _AmenityDot(
                          icon: Icons.park_rounded,
                          active: farm.hasShade,
                          tooltip: 'Shade'),
                      _AmenityDot(
                          icon: Icons.fence_rounded,
                          active: farm.hasFencing,
                          tooltip: 'Fencing'),
                      _AmenityDot(
                          icon: Icons.medical_services_rounded,
                          active: farm.hasVetNearby,
                          tooltip: 'Vet Nearby'),
                      const Spacer(),
                      Text(
                        '₹${farm.pricePerDayPerAnimal.toStringAsFixed(0)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                      Text(' /day/animal',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.landscape_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text('${farm.areaInAcres.toStringAsFixed(1)} acres',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.groups_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text('Max ${farm.maxAnimals}',
                          style: Theme.of(context).textTheme.bodySmall),
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
        height: 160,
        width: double.infinity,
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.landscape_rounded,
            size: 56, color: AppColors.textDisabled),
      );
}

class _DistanceBadge extends StatelessWidget {
  final String label;
  const _DistanceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AmenityDot extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String tooltip;

  const _AmenityDot(
      {required this.icon, required this.active, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primaryContainer : AppColors.surfaceVariant,
        ),
        child: Icon(icon,
            size: 14,
            color: active ? AppColors.primary : AppColors.textDisabled),
      ),
    );
  }
}

// ─── Location permission view ─────────────────────────────────────────────────

class _LocationPermissionView extends StatelessWidget {
  final VoidCallback onRequest;
  const _LocationPermissionView({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_rounded,
              size: 80, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.base),
          Text('Location Required',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'JeevaMitra needs your location to show nearby grazing lands.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onRequest,
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _FilterState initial;
  final ValueChanged<_FilterState> onApply;

  const _FilterSheet({required this.initial, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _FilterState _filter;

  static const _fodderOptions = [
    ('grass', '🌿 Grass'),
    ('sorghum', '🌾 Sorghum'),
    ('maize', '🌽 Maize'),
    ('cotton', '🪴 Cotton'),
    ('groundnut', '🥜 Groundnut'),
    ('paddy', '🌾 Paddy'),
    ('sugarcane', '🎋 Sugarcane'),
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                  top: AppSpacing.md, bottom: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(
              children: [
                Text('Filters',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      setState(() => _filter = const _FilterState()),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: AppSpacing.screenPadding,
              children: [
                Text('Fodder Type',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _fodderOptions.map((opt) {
                    final sel = _filter.fodderTypes.contains(opt.$1);
                    return FilterChip(
                      label: Text(opt.$2),
                      selected: sel,
                      onSelected: (_) {
                        final list = List<String>.from(_filter.fodderTypes);
                        if (sel) {
                          list.remove(opt.$1);
                        } else {
                          list.add(opt.$1);
                        }
                        setState(
                            () => _filter = _filter.copyWith(fodderTypes: list));
                      },
                      selectedColor: AppColors.primaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Amenities',
                    style: Theme.of(context).textTheme.titleSmall),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Water Available'),
                  value: _filter.onlyWater,
                  onChanged: (v) =>
                      setState(() => _filter = _filter.copyWith(onlyWater: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Shade / Trees'),
                  value: _filter.onlyShade,
                  onChanged: (v) =>
                      setState(() => _filter = _filter.copyWith(onlyShade: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fencing'),
                  value: _filter.onlyFencing,
                  onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(onlyFencing: v)),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Text('Max Price / Day / Animal',
                        style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    if (_filter.maxPricePerDay != null)
                      Text('₹${_filter.maxPricePerDay!.toInt()}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.primary)),
                  ],
                ),
                Slider(
                  min: 0,
                  max: 500,
                  divisions: 20,
                  value: _filter.maxPricePerDay ?? 500,
                  label: _filter.maxPricePerDay == null
                      ? 'Any'
                      : '₹${_filter.maxPricePerDay!.toInt()}',
                  onChanged: (v) => setState(() => _filter = _filter.copyWith(
                      maxPricePerDay: v < 500 ? v : null,
                      clearMaxPrice: v >= 500)),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
          Padding(
            padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.xl),
            child: FilledButton(
              onPressed: () {
                widget.onApply(_filter);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, AppSpacing.buttonHeight),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
