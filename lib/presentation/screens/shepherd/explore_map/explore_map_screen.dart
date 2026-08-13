import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vet/vet_providers.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/nearby_land_card.dart';
import '../../../widgets/explore/premium_vet_card.dart';
import '../../../widgets/explore/retry_card.dart';
import '../../../widgets/explore/search_card.dart';
import 'map_cluster.dart';
import 'unified_explore_filter.dart';

/// Unified Explore: an interactive Google Map showing both nearby lands
/// and nearby vets as clustered markers, with a draggable bottom sheet
/// holding search + filters + a combined result list — the same
/// [UnifiedExploreFilter] drives the markers on the map and the cards in
/// the sheet, so neither view can ever disagree with the other.
///
/// Reachable from Nearby Lands and Vets Nearby via a map icon in their
/// AppBars — not a new bottom-nav tab, so the existing 5-tab shepherd
/// shell is untouched.
class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen> {
  UnifiedExploreFilter _filter = const UnifiedExploreFilter();

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
      appBar: AppBar(title: Text(loc.exploreMapTitle)),
      body: locAsync.isLoading
          ? const Center(child: JmLoading())
          : locAsync.hasError
              ? EmptyStateCard(
                  icon: Icons.location_off_rounded,
                  title: loc.locationErrorTitle,
                  subtitle: locAsync.error?.toString().replaceFirst('Exception: ', '') ??
                      loc.couldNotGetLocationMsg,
                  accentColor: AppColors.error,
                  buttonLabel: loc.retryBtn,
                  onButtonTap: () => ref.read(locationProvider.notifier).fetch(),
                )
              : locAsync.valueOrNull == null
                  ? EmptyStateCard(
                      icon: Icons.location_off_rounded,
                      title: loc.locationRequiredTitle,
                      subtitle: loc.locationNeededMapMsg,
                      buttonLabel: loc.enableLocationBtn,
                      onButtonTap: () => ref.read(locationProvider.notifier).fetch(),
                    )
                  : _MapWithSheet(
                      lat: locAsync.value!.lat,
                      lng: locAsync.value!.lng,
                      filter: _filter,
                      onFilterChanged: (f) => setState(() => _filter = f),
                    ),
    );
  }
}

class _MapWithSheet extends ConsumerStatefulWidget {
  final double lat, lng;
  final UnifiedExploreFilter filter;
  final ValueChanged<UnifiedExploreFilter> onFilterChanged;

  const _MapWithSheet({
    required this.lat,
    required this.lng,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<_MapWithSheet> createState() => _MapWithSheetState();
}

class _MapWithSheetState extends ConsumerState<_MapWithSheet> {
  GoogleMapController? _mapCtrl;
  double _zoom = 11;

  static const _radii = [10.0, 25.0, 50.0, 100.0];

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _focusOn(double lat, double lng, {double? zoom}) async {
    await _mapCtrl?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), zoom ?? (_zoom + 2).clamp(2, 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final farmsAsync = ref.watch(nearbyFarmsProvider((
      lat: widget.lat,
      lng: widget.lng,
      radiusKm: widget.filter.radiusKm,
    )));
    final vetsAsync = ref.watch(nearbyVetsProvider((
      lat: widget.lat,
      lng: widget.lng,
      radiusKm: widget.filter.radiusKm,
    )));

    // Both providers are independent StreamProviders (Firestore reads for
    // farms and vets are separate collections — there is no single query
    // that could return both, and combining them client-side here is the
    // only option without touching either repository, which is out of
    // scope for this batch).
    final farmsError = farmsAsync.hasError ? farmsAsync.error : null;
    final vetsError = !farmsAsync.hasError && vetsAsync.hasError ? vetsAsync.error : null;
    final combinedError = farmsError ?? vetsError;

    if (farmsAsync.isLoading || vetsAsync.isLoading) {
      return const Center(child: JmLoading());
    }
    if (combinedError != null) {
      return RetryCard(
        error: combinedError,
        onRetry: () {
          ref.invalidate(nearbyFarmsProvider);
          ref.invalidate(nearbyVetsProvider);
        },
      );
    }

    final farms = widget.filter.applyToFarms(farmsAsync.valueOrNull ?? []);
    final vets = widget.filter.applyToVets(vetsAsync.valueOrNull ?? []);

    final mapEntities = [
      ...farms.map((f) => MapEntity(id: f.id, type: MapEntityType.land, lat: f.lat, lng: f.lng)),
      ...vets.map((v) => MapEntity(id: v.id, type: MapEntityType.vet, lat: v.lat, lng: v.lng)),
    ];
    final clusters = clusterEntities(mapEntities, _zoom);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: LatLng(widget.lat, widget.lng), zoom: _zoom),
          onMapCreated: (c) => _mapCtrl = c,
          onCameraMove: (pos) => _zoom = pos.zoom,
          onCameraIdle: () => setState(() {}),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          markers: _buildMarkers(clusters, loc),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.32,
          minChildSize: 0.14,
          maxChildSize: 0.85,
          builder: (context, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.zero,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
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
                  child: SearchCard(
                    hint: loc.searchMapHint,
                    onChanged: (v) => widget.onFilterChanged(widget.filter.copyWith(query: v)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: AppSpacing.screenHPadding,
                    children: [
                      ..._radii.map((r) {
                        final active = r == widget.filter.radiusKm;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(loc.kmChipLabel(r.toInt())),
                            selected: active,
                            onSelected: (_) =>
                                widget.onFilterChanged(widget.filter.copyWith(radiusKm: r)),
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          avatar: const Icon(Icons.landscape_rounded, size: 16),
                          label: Text(loc.landsChipLabel),
                          selected: widget.filter.showLands,
                          onSelected: (v) =>
                              widget.onFilterChanged(widget.filter.copyWith(showLands: v)),
                          selectedColor: AppColors.primaryContainer,
                        ),
                      ),
                      FilterChip(
                        avatar: const Icon(Icons.medical_services_rounded, size: 16),
                        label: Text(loc.vets),
                        selected: widget.filter.showVets,
                        onSelected: (v) =>
                            widget.onFilterChanged(widget.filter.copyWith(showVets: v)),
                        selectedColor: AppColors.secondaryContainer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  child: Text(
                    loc.resultsWithinRadiusMsg(
                        farms.length + vets.length, widget.filter.radiusKm.toInt()),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (farms.isEmpty && vets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: EmptyStateCard(
                      icon: Icons.search_off_rounded,
                      title: loc.nothingFoundTitle,
                      subtitle: loc.tryDifferentSearchMsg,
                    ),
                  )
                else ...[
                  ...farms.map((f) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.base, 0, AppSpacing.base, AppSpacing.md),
                        child: NearbyLandCard(
                          farm: f,
                          distanceKm: GeoHashHelper.distanceKm(widget.lat, widget.lng, f.lat, f.lng),
                          onViewDetails: () =>
                              context.push(RouteConstants.shepherdLand(f.id)),
                        ),
                      )),
                  ...vets.map((v) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.base, 0, AppSpacing.base, AppSpacing.md),
                        child: PremiumVetCard(
                          vet: v,
                          distanceKm: GeoHashHelper.distanceKm(widget.lat, widget.lng, v.lat, v.lng),
                          onViewProfile: () => context.push(RouteConstants.vetDetail(v.id)),
                        ),
                      )),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Set<Marker> _buildMarkers(List<MapCluster> clusters, AppLocalizations loc) {
    return clusters.map((cluster) {
      if (!cluster.isCluster) {
        final entity = cluster.entities.first;
        final isLand = entity.type == MapEntityType.land;
        return Marker(
          markerId: MarkerId('${entity.type.name}-${entity.id}'),
          position: LatLng(cluster.lat, cluster.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              isLand ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure),
          onTap: () => isLand
              ? context.push(RouteConstants.shepherdLand(entity.id))
              : context.push(RouteConstants.vetDetail(entity.id)),
        );
      }
      // Cluster marker: tapping zooms in on the cluster rather than
      // opening a detail screen — a cluster represents multiple entities,
      // so there's no single detail to navigate to.
      final id = cluster.entities.map((e) => e.id).join('-');
      return Marker(
        markerId: MarkerId('cluster-$id'),
        position: LatLng(cluster.lat, cluster.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: loc.resultsHereMsg(cluster.entities.length)),
        onTap: () => _focusOn(cluster.lat, cluster.lng),
      );
    }).toSet();
  }
}
