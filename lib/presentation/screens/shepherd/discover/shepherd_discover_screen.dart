import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/nearby_land_card.dart';
import '../../../widgets/explore/retry_card.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/explore/loading_skeleton.dart';
import '../../farmer/lands/farmer_lands_screen.dart';
import 'discover_filter.dart';

// ─── Sort UI ──────────────────────────────────────────────────────────────────
// (DiscoverSortMode itself, and the rankFarms it drives, live in
// discover_filter.dart so they're unit-testable — this extension is purely
// presentational and stays local to the screen.)

extension on DiscoverSortMode {
  String labelFor(AppLocalizations loc) => switch (this) {
        DiscoverSortMode.closest => loc.sortClosestLabel,
        DiscoverSortMode.available => loc.availableNow,
        DiscoverSortMode.newest => loc.sortNewestLabel,
      };

  IconData get icon => switch (this) {
        DiscoverSortMode.closest => Icons.near_me_rounded,
        DiscoverSortMode.available => Icons.check_circle_outline_rounded,
        DiscoverSortMode.newest => Icons.fiber_new_rounded,
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ShepherdDiscoverScreen extends ConsumerStatefulWidget {
  const ShepherdDiscoverScreen({super.key});

  @override
  ConsumerState<ShepherdDiscoverScreen> createState() =>
      _ShepherdDiscoverScreenState();
}

class _ShepherdDiscoverScreenState
    extends ConsumerState<ShepherdDiscoverScreen> {
  DiscoverFilterState _filter = const DiscoverFilterState();
  DiscoverSortMode _sort = DiscoverSortMode.closest;

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
    final loc = AppLocalizations.of(context);
    final locAsync = ref.watch(locationProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(loc.discoverLandsBtn),
            floating: true,
            snap: true,
            actions: [
              // Universal Access: posting/managing your own land is
              // available to every profile, not just this tab's default
              // (discover) view.
              IconButton(
                icon: const Icon(Icons.landscape_rounded),
                tooltip: loc.myLands,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FarmerLandsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: loc.searchEverythingTooltip,
                onPressed: () => context.push(RouteConstants.unifiedSearch),
              ),
              IconButton(
                icon: const Icon(Icons.map_rounded),
                tooltip: loc.mapViewTooltip,
                onPressed: () =>
                    context.push(RouteConstants.shepherdExploreMap),
              ),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: loc.filtersLabel,
                    onPressed: () => _showFilterSheet(context),
                  ),
                  if (_filter.hasActiveFilters)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(96),
              child: Column(
                children: [
                  _RadiusBar(
                    selected: _filter.radiusKm,
                    radii: _radii,
                    onSelect: (r) =>
                        setState(() => _filter = _filter.copyWith(radiusKm: r)),
                  ),
                  _SortBar(
                    selected: _sort,
                    loc: loc,
                    onSelect: (s) => setState(() => _sort = s),
                  ),
                ],
              ),
            ),
          ),
          if (locAsync.isLoading)
            const SliverFillRemaining(child: Center(child: JmLoading()))
          else if (locAsync.hasError)
            SliverFillRemaining(
              // Not RetryCard here deliberately: LocationService throws a
              // plain Exception with an already-specific, human-readable
              // message ("Location services are disabled...", "Location
              // permission denied...") — routing it through
              // friendlyFirebaseMessage (which only recognizes
              // FirebaseException/FirebaseAuthException) would discard
              // that and replace it with a generic fallback.
              child: EmptyStateCard(
                icon: Icons.location_off_rounded,
                title: loc.locationErrorTitle,
                subtitle: locAsync.error
                        ?.toString()
                        .replaceFirst('Exception: ', '') ??
                    loc.couldNotGetLocationMsg,
                accentColor: AppColors.error,
                buttonLabel: loc.retryBtn,
                onButtonTap: () => ref.read(locationProvider.notifier).fetch(),
              ),
            )
          else if (locAsync.valueOrNull == null)
            SliverFillRemaining(
              child: _LocationPermissionView(
                loc: loc,
                onRequest: () => ref.read(locationProvider.notifier).fetch(),
              ),
            )
          else
            _FarmList(
              lat: locAsync.value!.lat,
              lng: locAsync.value!.lng,
              filter: _filter,
              sort: _sort,
              loc: loc,
              onClearFilters: () =>
                  setState(() => _filter = const DiscoverFilterState()),
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

  const _RadiusBar(
      {required this.selected, required this.radii, required this.onSelect});

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
            padding:
                const EdgeInsets.only(right: AppSpacing.sm, top: 8, bottom: 8),
            child: ChoiceChip(
              label: Text(AppLocalizations.of(context).kmChipLabel(r.toInt())),
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

// ─── Sort bar ─────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final DiscoverSortMode selected;
  final AppLocalizations loc;
  final ValueChanged<DiscoverSortMode> onSelect;

  const _SortBar({required this.selected, required this.loc, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenHPadding,
        children: DiscoverSortMode.values.map((s) {
          final active = s == selected;
          return Padding(
            padding:
                const EdgeInsets.only(right: AppSpacing.sm, top: 8, bottom: 8),
            child: ChoiceChip(
              avatar: Icon(s.icon,
                  size: 16,
                  color: active ? AppColors.primary : AppColors.textSecondary),
              label: Text(loc.sortByLabel(s.labelFor(loc))),
              selected: active,
              onSelected: (_) => onSelect(s),
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
  final DiscoverFilterState filter;
  final DiscoverSortMode sort;
  final AppLocalizations loc;
  final VoidCallback onClearFilters;

  const _FarmList({
    required this.lat,
    required this.lng,
    required this.filter,
    required this.sort,
    required this.loc,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(nearbyFarmsProvider((
      lat: lat,
      lng: lng,
      radiusKm: filter.radiusKm,
    )));

    return farmsAsync.when(
      loading: () => const SliverFillRemaining(
        child: LoadingSkeleton(count: 4),
      ),
      error: (e, _) => SliverFillRemaining(
        child: RetryCard(
          error: e,
          onRetry: () => ref.invalidate(nearbyFarmsProvider),
        ),
      ),
      data: (all) {
        final filtered = filter.apply(all);
        if (filtered.isEmpty) {
          return SliverFillRemaining(
            child: EmptyStateCard(
              icon: Icons.search_off_rounded,
              title: loc.noLandsFoundTitle,
              subtitle: filter.hasActiveFilters
                  ? loc.tryFewerFiltersMsg
                  : loc.noAvailableLandRadiusMsg(filter.radiusKm.toInt()),
              buttonLabel: filter.hasActiveFilters ? loc.clearFiltersBtn : null,
              onButtonTap: filter.hasActiveFilters ? onClearFilters : null,
            ),
          );
        }
        final ranked = rankFarms(filtered, lat, lng, sort);
        return SliverPadding(
          padding: AppSpacing.screenPadding,
          sliver: SliverList.separated(
            itemCount: ranked.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final (farm, distanceKm) = ranked[i];
              return NearbyLandCard(
                farm: farm,
                distanceKm: distanceKm,
                onViewDetails: () =>
                    context.push(RouteConstants.shepherdLand(farm.id)),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Location permission view ─────────────────────────────────────────────────

class _LocationPermissionView extends StatelessWidget {
  final AppLocalizations loc;
  final VoidCallback onRequest;
  const _LocationPermissionView({required this.loc, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.location_off_rounded,
      title: loc.locationRequiredTitle,
      subtitle: loc.locationNeededLandsMsg,
      buttonLabel: loc.enableLocationBtn,
      onButtonTap: onRequest,
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final DiscoverFilterState initial;
  final ValueChanged<DiscoverFilterState> onApply;

  const _FilterSheet({required this.initial, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DiscoverFilterState _filter;
  late final _villageCtrl = TextEditingController(text: widget.initial.village);
  late final _districtCtrl =
      TextEditingController(text: widget.initial.district);

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
  void dispose() {
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
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
                Text(loc.filtersLabel, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _filter = const DiscoverFilterState();
                    _villageCtrl.clear();
                    _districtCtrl.clear();
                  }),
                  child: Text(loc.resetBtn),
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
                Text(loc.availableNow,
                    style: Theme.of(context).textTheme.titleSmall),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.showUnavailableLabel),
                  value: _filter.includeUnavailable,
                  onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(includeUnavailable: v)),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(loc.locationLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _villageCtrl,
                  decoration: InputDecoration(
                    labelText: loc.villageFieldLabel,
                    prefixIcon: const Icon(Icons.location_city_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) => _filter = _filter.copyWith(village: v),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _districtCtrl,
                  decoration: InputDecoration(
                    labelText: loc.yourDistrict,
                    prefixIcon: const Icon(Icons.map_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) => _filter = _filter.copyWith(district: v),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(loc.areaAcresLabel,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                RangeSlider(
                  min: 0,
                  max: 50,
                  divisions: 25,
                  values: RangeValues(
                      _filter.minAcres ?? 0, _filter.maxAcres ?? 50),
                  labels: RangeLabels(
                    _filter.minAcres == null
                        ? loc.anyLabel
                        : _filter.minAcres!.toStringAsFixed(0),
                    _filter.maxAcres == null
                        ? loc.anyLabel
                        : _filter.maxAcres!.toStringAsFixed(0),
                  ),
                  onChanged: (v) => setState(() {
                    _filter = _filter.copyWith(
                      minAcres: v.start > 0 ? v.start : null,
                      clearMinAcres: v.start <= 0,
                      maxAcres: v.end < 50 ? v.end : null,
                      clearMaxAcres: v.end >= 50,
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(loc.fodderTypeLabel,
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
                        setState(() =>
                            _filter = _filter.copyWith(fodderTypes: list));
                      },
                      selectedColor: AppColors.primaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(loc.amenities,
                    style: Theme.of(context).textTheme.titleSmall),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.waterAvailableLabel),
                  value: _filter.onlyWater,
                  onChanged: (v) =>
                      setState(() => _filter = _filter.copyWith(onlyWater: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.shadeTreesLabel),
                  value: _filter.onlyShade,
                  onChanged: (v) =>
                      setState(() => _filter = _filter.copyWith(onlyShade: v)),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.fencing),
                  value: _filter.onlyFencing,
                  onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(onlyFencing: v)),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Text(loc.maxPriceLabel,
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
                      ? loc.anyLabel
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
              child: Text(loc.applyFiltersBtn),
            ),
          ),
        ],
      ),
    );
  }
}
