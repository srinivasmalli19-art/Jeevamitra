import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/disease_alert_model.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../../data/models/farm_model.dart';
import '../../../../data/models/vet_model.dart';
import '../../../providers/alerts/disease_alert_providers.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vet/vet_providers.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/common/responsive_center.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/loading_skeleton.dart';
import '../../../widgets/explore/retry_card.dart';
import '../../../widgets/explore/search_card.dart';
import '../../../widgets/explore/search_result_tile.dart';
import 'search_result.dart';

/// One premium search across the whole Explore module: Nearby Lands,
/// Nearby Vets, Disease Alerts, Villages, and Districts, all in a single
/// result list. Reachable from the Farmer Explore header and the Discover
/// / Vets Nearby AppBars (a search icon alongside the existing map icon),
/// matching the "no new bottom-nav tab" precedent set for the Explore Map.
///
/// Reads three already-existing streams (farms, vets, alerts) and does no
/// Firestore queries of its own — Villages/Districts are synthesized from
/// that same data, not a separate read.
class UnifiedSearchScreen extends ConsumerStatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  ConsumerState<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends ConsumerState<UnifiedSearchScreen> {
  static const _radiusKm = 100.0;
  static const _alertRadiusKm = 150.0;

  String _query = '';

  // Manual memoization: rebuilding this screen (e.g. keyboard inset
  // changes) is common and must not re-run the search over every
  // keystroke's unrelated rebuild — only recompute when the query or one
  // of the three source lists actually changed identity.
  String? _cachedQuery;
  List<FarmModel> _cachedFarms = const [];
  List<VetModel> _cachedVets = const [];
  List<DiseaseAlertModel> _cachedAlerts = const [];
  List<SearchResultItem> _cachedResults = const [];

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

  List<SearchResultItem> _resultsFor({
    required double lat,
    required double lng,
    required List<FarmModel> farms,
    required List<VetModel> vets,
    required List<DiseaseAlertModel> alerts,
  }) {
    if (_query == _cachedQuery &&
        identical(farms, _cachedFarms) &&
        identical(vets, _cachedVets) &&
        identical(alerts, _cachedAlerts)) {
      return _cachedResults;
    }
    final results = buildSearchResults(
      query: _query,
      userLat: lat,
      userLng: lng,
      farms: farms,
      vets: vets,
      alerts: alerts,
    );
    _cachedQuery = _query;
    _cachedFarms = farms;
    _cachedVets = vets;
    _cachedAlerts = alerts;
    _cachedResults = results;
    return results;
  }

  void _onResultTap(SearchResultItem r) {
    switch (r.category) {
      case SearchResultCategory.land:
        context.push(RouteConstants.shepherdLand(r.id));
      case SearchResultCategory.vet:
        context.push(RouteConstants.vetDetail(r.id));
      case SearchResultCategory.alert:
        context.push(RouteConstants.alertDetail(r.id));
      case SearchResultCategory.village:
      case SearchResultCategory.district:
        context.push(RouteConstants.shepherdDiscover);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.searchTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchCard(
                  hint: loc.searchEverythingHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.base),
                Expanded(child: _buildBody(loc)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_query.trim().isEmpty) {
      return EmptyStateCard(
        icon: Icons.travel_explore_rounded,
        title: loc.searchEverythingTitle,
        subtitle: loc.searchEverythingDesc,
      );
    }

    final locAsync = ref.watch(locationProvider);

    if (locAsync.isLoading) {
      return const Center(child: JmLoading());
    }
    if (locAsync.hasError || locAsync.valueOrNull == null) {
      return EmptyStateCard(
        icon: Icons.location_off_rounded,
        title: loc.locationRequiredTitle,
        subtitle: loc.locationNeededSearchMsg,
        buttonLabel: loc.enableLocationBtn,
        onButtonTap: () => ref.read(locationProvider.notifier).fetch(),
      );
    }

    final userLoc = locAsync.value!;
    final farmsAsync = ref
        .watch(nearbyFarmsProvider((lat: userLoc.lat, lng: userLoc.lng, radiusKm: _radiusKm)));
    final vetsAsync = ref
        .watch(nearbyVetsProvider((lat: userLoc.lat, lng: userLoc.lng, radiusKm: _radiusKm)));
    final alertsAsync = ref.watch(nearbyAlertsProvider(
        (lat: userLoc.lat, lng: userLoc.lng, radiusKm: _alertRadiusKm)));

    if (farmsAsync.isLoading || vetsAsync.isLoading || alertsAsync.isLoading) {
      return const LoadingSkeleton(count: 4);
    }

    final error = farmsAsync.hasError
        ? farmsAsync.error
        : vetsAsync.hasError
            ? vetsAsync.error
            : alertsAsync.hasError
                ? alertsAsync.error
                : null;
    if (error != null) {
      return RetryCard(
        error: error,
        onRetry: () {
          ref.invalidate(nearbyFarmsProvider);
          ref.invalidate(nearbyVetsProvider);
          ref.invalidate(nearbyAlertsProvider);
        },
      );
    }

    final results = _resultsFor(
      lat: userLoc.lat,
      lng: userLoc.lng,
      farms: farmsAsync.valueOrNull ?? const [],
      vets: vetsAsync.valueOrNull ?? const [],
      alerts: alertsAsync.valueOrNull ?? const [],
    );

    if (results.isEmpty) {
      return EmptyStateCard(
        icon: Icons.search_off_rounded,
        title: loc.noResultsTitle,
        subtitle: loc.noResultsMsg(_query),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) =>
          SearchResultTile(result: results[i], onTap: () => _onResultTap(results[i])),
    );
  }
}
