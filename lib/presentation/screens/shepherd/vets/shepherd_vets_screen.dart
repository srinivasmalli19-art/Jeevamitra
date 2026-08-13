import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vet/vet_providers.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/premium_vet_card.dart';
import '../../../widgets/explore/retry_card.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/explore/loading_skeleton.dart';
import 'vet_filter.dart';

// ─── Sort UI ──────────────────────────────────────────────────────────────────
// (VetSortMode itself, and the rankVets it drives, live in vet_filter.dart
// so they're unit-testable — this extension is purely presentational.)

extension on VetSortMode {
  String labelFor(AppLocalizations loc) => switch (this) {
        VetSortMode.closest => loc.sortClosestLabel,
        VetSortMode.highestRated => loc.sortTopRatedLabel,
        VetSortMode.mostExperienced => loc.sortExperiencedLabel,
        VetSortMode.availableToday => loc.availableTodayLabel,
      };

  IconData get icon => switch (this) {
        VetSortMode.closest => Icons.near_me_rounded,
        VetSortMode.highestRated => Icons.star_rounded,
        VetSortMode.mostExperienced => Icons.work_history_rounded,
        VetSortMode.availableToday => Icons.event_available_rounded,
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ShepherdVetsScreen extends ConsumerStatefulWidget {
  const ShepherdVetsScreen({super.key});

  @override
  ConsumerState<ShepherdVetsScreen> createState() => _ShepherdVetsScreenState();
}

class _ShepherdVetsScreenState extends ConsumerState<ShepherdVetsScreen> {
  VetFilterState _filter = const VetFilterState();
  VetSortMode _sort = VetSortMode.closest;

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
            title: Text(loc.nearbyVets),
            floating: true,
            snap: true,
            actions: [
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
                      onSelect: (s) => setState(() => _sort = s)),
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
              // message — routing it through friendlyFirebaseMessage
              // (which only recognizes FirebaseException/
              // FirebaseAuthException) would discard that for a generic
              // fallback. Same reasoning as Batch 2B's Nearby Lands screen.
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
            _VetList(
              lat: locAsync.value!.lat,
              lng: locAsync.value!.lng,
              filter: _filter,
              sort: _sort,
              loc: loc,
              onClearFilters: () =>
                  setState(() => _filter = const VetFilterState()),
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
  final VetSortMode selected;
  final AppLocalizations loc;
  final ValueChanged<VetSortMode> onSelect;

  const _SortBar({required this.selected, required this.loc, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenHPadding,
        children: VetSortMode.values.map((s) {
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

// ─── Vet list ─────────────────────────────────────────────────────────────────

class _VetList extends ConsumerWidget {
  final double lat, lng;
  final VetFilterState filter;
  final VetSortMode sort;
  final AppLocalizations loc;
  final VoidCallback onClearFilters;

  const _VetList({
    required this.lat,
    required this.lng,
    required this.filter,
    required this.sort,
    required this.loc,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vetsAsync = ref.watch(nearbyVetsProvider((
      lat: lat,
      lng: lng,
      radiusKm: filter.radiusKm,
    )));

    return vetsAsync.when(
      loading: () => const SliverFillRemaining(
        child: LoadingSkeleton(count: 4),
      ),
      error: (e, _) => SliverFillRemaining(
        child: RetryCard(
            error: e, onRetry: () => ref.invalidate(nearbyVetsProvider)),
      ),
      data: (all) {
        final filtered = filter.apply(all);
        if (filtered.isEmpty) {
          return SliverFillRemaining(
            child: EmptyStateCard(
              icon: Icons.medical_services_rounded,
              title: loc.noVetsFoundTitle,
              subtitle: filter.hasActiveFilters
                  ? loc.tryFewerFiltersMsg
                  : loc.noVetsFoundRadiusMsg(filter.radiusKm.toInt()),
              buttonLabel: filter.hasActiveFilters ? loc.clearFiltersBtn : null,
              onButtonTap: filter.hasActiveFilters ? onClearFilters : null,
            ),
          );
        }
        final ranked = rankVets(filtered, lat, lng, sort);
        return SliverPadding(
          padding: AppSpacing.screenPadding,
          sliver: SliverList.separated(
            itemCount: ranked.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final (vet, distanceKm) = ranked[i];
              return PremiumVetCard(
                vet: vet,
                distanceKm: distanceKm,
                onViewProfile: () =>
                    context.push(RouteConstants.vetDetail(vet.id)),
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
      subtitle: loc.locationNeededVetsMsg,
      buttonLabel: loc.enableLocationBtn,
      onButtonTap: onRequest,
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final VetFilterState initial;
  final ValueChanged<VetFilterState> onApply;

  const _FilterSheet({required this.initial, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late VetFilterState _filter;
  late final _villageCtrl = TextEditingController(text: widget.initial.village);
  late final _districtCtrl =
      TextEditingController(text: widget.initial.district);

  static const _languages = ['Telugu', 'Hindi', 'English', 'Kannada', 'Tamil'];
  static const _specializations = [
    'Large Animal Medicine',
    'Small Ruminants',
    'Poultry',
    'Surgery',
    'General Practice',
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
                Text(loc.filterVetsTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _filter = const VetFilterState();
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.account_balance_rounded),
                  title: Text(loc.govtVetsOnlyLabel),
                  subtitle: Text(loc.govtVetsOnlySubtitle),
                  value: _filter.onlyGovt,
                  onChanged: (v) =>
                      setState(() => _filter = _filter.copyWith(onlyGovt: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.event_available_rounded),
                  title: Text(loc.availableTodayLabel),
                  value: _filter.onlyAvailableToday,
                  onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(onlyAvailableToday: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.money_off_rounded),
                  title: Text(loc.freeConsultationLabel),
                  value: _filter.onlyFree,
                  onChanged: (v) =>
                      setState(() => _filter = _filter.copyWith(onlyFree: v)),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(loc.minimumRatingLabel,
                    style: Theme.of(context).textTheme.titleSmall),
                Slider(
                  min: 0,
                  max: 5,
                  divisions: 10,
                  value: _filter.minRating,
                  label: _filter.minRating == 0
                      ? loc.anyLabel
                      : loc.ratingStarsLabel(_filter.minRating.toString()),
                  onChanged: (v) =>
                      setState(() => _filter = _filter.copyWith(minRating: v)),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(loc.minimumExperienceLabel,
                    style: Theme.of(context).textTheme.titleSmall),
                Slider(
                  min: 0,
                  max: 30,
                  divisions: 30,
                  value: _filter.minExperience.toDouble(),
                  label: _filter.minExperience == 0
                      ? loc.anyLabel
                      : loc.yearsShortLabel(_filter.minExperience),
                  onChanged: (v) => setState(() =>
                      _filter = _filter.copyWith(minExperience: v.round())),
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
                Text(loc.specializationLabel,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _specializations.map((s) {
                    final sel = _filter.specialization == s;
                    return FilterChip(
                      label: Text(s),
                      selected: sel,
                      onSelected: (_) => setState(() => _filter =
                          _filter.copyWith(
                              specialization: sel ? null : s,
                              clearSpecialization: sel)),
                      selectedColor: AppColors.primaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(loc.languageLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _languages.map((l) {
                    final sel = _filter.language == l;
                    return FilterChip(
                      label: Text(l),
                      selected: sel,
                      onSelected: (_) => setState(() => _filter =
                          _filter.copyWith(
                              language: sel ? null : l, clearLanguage: sel)),
                      selectedColor: AppColors.primaryContainer,
                    );
                  }).toList(),
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
