import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/vet_model.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vet/vet_providers.dart';
import '../../../widgets/common/jm_empty_state.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';

// ─── Filter state ─────────────────────────────────────────────────────────────

class _VetFilter {
  final double radiusKm;
  final bool onlyGovt;
  final bool only24x7;
  final bool onlyFree;

  const _VetFilter({
    this.radiusKm = 50,
    this.onlyGovt = false,
    this.only24x7 = false,
    this.onlyFree = false,
  });

  _VetFilter copyWith({
    double? radiusKm,
    bool? onlyGovt,
    bool? only24x7,
    bool? onlyFree,
  }) =>
      _VetFilter(
        radiusKm: radiusKm ?? this.radiusKm,
        onlyGovt: onlyGovt ?? this.onlyGovt,
        only24x7: only24x7 ?? this.only24x7,
        onlyFree: onlyFree ?? this.onlyFree,
      );

  bool get hasActive => onlyGovt || only24x7 || onlyFree;

  List<VetModel> apply(List<VetModel> vets) => vets.where((v) {
        if (onlyGovt && !v.isGovtVet) return false;
        if (only24x7 && !v.isAvailable24x7) return false;
        if (onlyFree && !v.isFree) return false;
        return true;
      }).toList();
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ShepherdVetsScreen extends ConsumerStatefulWidget {
  const ShepherdVetsScreen({super.key});

  @override
  ConsumerState<ShepherdVetsScreen> createState() => _ShepherdVetsScreenState();
}

class _ShepherdVetsScreenState extends ConsumerState<ShepherdVetsScreen> {
  _VetFilter _filter = const _VetFilter();

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
            title: const Text('Vets Nearby'),
            floating: true,
            snap: true,
            actions: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Filter',
                    onPressed: () => _showFilterSheet(context),
                  ),
                  if (_filter.hasActive)
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
              preferredSize: const Size.fromHeight(48),
              child: _RadiusBar(
                selected: _filter.radiusKm,
                radii: _radii,
                onSelect: (r) =>
                    setState(() => _filter = _filter.copyWith(radiusKm: r)),
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
            _VetList(
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

// ─── Vet list ─────────────────────────────────────────────────────────────────

class _VetList extends ConsumerWidget {
  final double lat, lng;
  final _VetFilter filter;

  const _VetList(
      {required this.lat, required this.lng, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vetsAsync = ref.watch(nearbyVetsProvider((
      lat: lat,
      lng: lng,
      radiusKm: filter.radiusKm,
    )));

    return vetsAsync.when(
      loading: () => const SliverFillRemaining(
        child: JmShimmerList(count: 4, cardHeight: 120),
      ),
      error: (e, _) => SliverFillRemaining(
        child: JmErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(nearbyVetsProvider),
          isNetwork: true,
        ),
      ),
      data: (all) {
        final vets = filter.apply(all);
        if (vets.isEmpty) {
          return SliverFillRemaining(
            child: JmEmptyState(
              icon: Icons.medical_services_rounded,
              title: 'No Vets Found',
              subtitle: filter.hasActive
                  ? 'Try removing filters or increasing the radius.'
                  : 'No veterinarians found within ${filter.radiusKm.toInt()} km.',
            ),
          );
        }
        return SliverPadding(
          padding: AppSpacing.screenPadding,
          sliver: SliverList.separated(
            itemCount: vets.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) =>
                _VetCard(vet: vets[i], userLat: lat, userLng: lng),
          ),
        );
      },
    );
  }
}

// ─── Vet card ─────────────────────────────────────────────────────────────────

class _VetCard extends StatelessWidget {
  final VetModel vet;
  final double userLat, userLng;

  const _VetCard(
      {required this.vet, required this.userLat, required this.userLng});

  @override
  Widget build(BuildContext context) {
    final distKm =
        LocationService().distanceBetween(userLat, userLng, vet.lat, vet.lng);
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
        onTap: () => context.push(RouteConstants.vetDetail(vet.id)),
        borderRadius: AppSpacing.cardRadius,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: vet.profileImageUrl != null
                    ? NetworkImage(vet.profileImageUrl!)
                    : null,
                child: vet.profileImageUrl == null
                    ? Text(
                        vet.name.isNotEmpty ? vet.name[0].toUpperCase() : 'V',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vet.name,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vet.isVerified)
                          const Icon(Icons.verified_rounded,
                              size: 16, color: AppColors.info),
                      ],
                    ),
                    Text(
                      vet.qualification,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(vet.village,
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(distLabel,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        if (vet.isGovtVet)
                          _MiniChip(
                              label: 'Govt',
                              color: AppColors.info,
                              bg: AppColors.infoContainer),
                        if (vet.isAvailable24x7)
                          _MiniChip(
                              label: '24×7',
                              color: AppColors.success,
                              bg: AppColors.successContainer),
                        if (vet.isFree)
                          _MiniChip(
                              label: 'Free',
                              color: AppColors.success,
                              bg: AppColors.successContainer)
                        else if (vet.consultationFee != null)
                          _MiniChip(
                              label:
                                  '₹${vet.consultationFee!.toStringAsFixed(0)}',
                              color: AppColors.secondary,
                              bg: AppColors.secondaryContainer),
                        if (vet.rating > 0)
                          _MiniChip(
                              label:
                                  '★ ${vet.rating.toStringAsFixed(1)}',
                              color: AppColors.warning,
                              bg: AppColors.warningContainer),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color, bg;

  const _MiniChip(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
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
            'Enable location to find veterinarians near your herd.',
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

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _VetFilter initial;
  final ValueChanged<_VetFilter> onApply;

  const _FilterSheet({required this.initial, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _VetFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filter Vets',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      setState(() => _filter = const _VetFilter()),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.account_balance_rounded),
              title: const Text('Government Vets Only'),
              subtitle: const Text('Subsidised / free services'),
              value: _filter.onlyGovt,
              onChanged: (v) =>
                  setState(() => _filter = _filter.copyWith(onlyGovt: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.access_time_filled_rounded),
              title: const Text('Available 24×7'),
              value: _filter.only24x7,
              onChanged: (v) =>
                  setState(() => _filter = _filter.copyWith(only24x7: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.money_off_rounded),
              title: const Text('Free Consultation'),
              value: _filter.onlyFree,
              onChanged: (v) =>
                  setState(() => _filter = _filter.copyWith(onlyFree: v)),
            ),
            const SizedBox(height: AppSpacing.base),
            FilledButton(
              onPressed: () {
                widget.onApply(_filter);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, AppSpacing.buttonHeight),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
