import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../core/utils/search_matcher.dart';
import '../../../../data/models/disease_alert_model.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/alerts/disease_alert_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/common/responsive_center.dart';
import '../../../widgets/explore/alert_card.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/loading_skeleton.dart';
import '../../../widgets/explore/retry_card.dart';
import '../../../widgets/explore/search_card.dart';
import 'alert_filter.dart';
import 'alert_filter_sheet.dart';

/// The modern Disease Alerts dashboard: search + advanced filters + a map
/// entry point, over four tabs (Nearby / District / Active / Recent) — all
/// four are lenses on just two real streams (`nearbyAlertsProvider`,
/// `districtAlertsProvider`); see `alert_filter.dart` for why no new
/// stream or collection is needed for "Active"/"Recent". Drop-in
/// replacement for the old `_DiseaseAlertsTab` in `farmer_explore_screen.dart`.
class AlertDashboard extends ConsumerStatefulWidget {
  const AlertDashboard({super.key});

  @override
  ConsumerState<AlertDashboard> createState() => _AlertDashboardState();
}

class _AlertDashboardState extends ConsumerState<AlertDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: AlertDashboardTab.values.length, vsync: this);
  AlertFilterState _filter = const AlertFilterState();
  String _query = '';

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
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AlertFilterSheet(
        initial: _filter,
        onApply: (f) => setState(() => _filter = f),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locAsync = ref.watch(locationProvider);

    if (locAsync.isLoading) {
      return const Center(child: JmLoading());
    }
    if (locAsync.hasError || locAsync.valueOrNull == null) {
      return EmptyStateCard(
        icon: Icons.location_off_rounded,
        title: loc.locationRequiredTitle,
        subtitle: loc.locationNeededAlertsMsg,
        buttonLabel: loc.enableLocationBtn,
        onButtonTap: () => ref.read(locationProvider.notifier).fetch(),
      );
    }

    final userLoc = locAsync.value!;

    return Column(
      children: [
        Padding(
          padding: AppSpacing.screenPadding,
          child: Row(
            children: [
              Expanded(
                child: SearchCard(
                  hint: loc.searchAlertDashboardHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Material(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.cardRadius,
                    child: IconButton(
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: loc.filtersLabel,
                      onPressed: _showFilterSheet,
                    ),
                  ),
                  if (_filter.hasActiveFilters)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.secondary, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Material(
                color: AppColors.surface,
                borderRadius: AppSpacing.cardRadius,
                child: IconButton(
                  icon: const Icon(Icons.map_rounded),
                  tooltip: loc.mapViewTooltip,
                  onPressed: () => context.push(RouteConstants.alertMap),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surfaceVariant,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: AlertDashboardTab.values
                .map((t) => Tab(text: t.labelFor(loc)))
                .toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: AlertDashboardTab.values
                .map((t) => _AlertTabBody(
                    tab: t,
                    lat: userLoc.lat,
                    lng: userLoc.lng,
                    filter: _filter,
                    query: _query,
                    loc: loc))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _AlertTabBody extends ConsumerWidget {
  final AlertDashboardTab tab;
  final double lat, lng;
  final AlertFilterState filter;
  final String query;
  final AppLocalizations loc;

  const _AlertTabBody({
    required this.tab,
    required this.lat,
    required this.lng,
    required this.filter,
    required this.query,
    required this.loc,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tab == AlertDashboardTab.district) {
      return _DistrictTabBody(lat: lat, lng: lng, filter: filter, query: query, loc: loc);
    }

    final alertsAsync = ref.watch(
        nearbyAlertsProvider((lat: lat, lng: lng, radiusKm: filter.radiusKm)));

    return alertsAsync.when(
      loading: () => const LoadingSkeleton(count: 3),
      error: (e, _) => RetryCard(
        error: e,
        onRetry: () => ref.invalidate(nearbyAlertsProvider),
      ),
      data: (all) {
        var result = filter.apply(all);
        result = result
            .where((a) => matchesQuery(
                query, [a.title, a.disease, a.village, a.district]))
            .toList();
        switch (tab) {
          case AlertDashboardTab.recent:
            result = sortByRecent(result);
          case AlertDashboardTab.active:
            result = urgentOnly(result);
          case AlertDashboardTab.nearby:
          case AlertDashboardTab.district:
            break;
        }
        return _AlertList(
            alerts: result,
            lat: lat,
            lng: lng,
            tab: tab,
            loc: loc,
            hasActiveFilters:
                filter.hasActiveFilters || query.trim().isNotEmpty);
      },
    );
  }
}

class _DistrictTabBody extends ConsumerWidget {
  final double lat, lng;
  final AlertFilterState filter;
  final String query;
  final AppLocalizations loc;

  const _DistrictTabBody(
      {required this.lat,
      required this.lng,
      required this.filter,
      required this.query,
      required this.loc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Shares the same nearbyAlertsProvider instance the Nearby tab already
    // watches (Riverpod caches by provider+params, so this is not a
    // duplicate stream) — used only to suggest a default district when the
    // user hasn't typed one in Filters, from data already on the wire.
    final nearbyAsync = ref.watch(
        nearbyAlertsProvider((lat: lat, lng: lng, radiusKm: filter.radiusKm)));

    final typedDistrict = filter.district.trim();
    final nearbyAlerts = nearbyAsync.valueOrNull ?? const <DiseaseAlertModel>[];
    final suggestedDistrict = typedDistrict.isNotEmpty
        ? typedDistrict
        : (nearbyAlerts.isNotEmpty ? nearbyAlerts.first.district : '');

    if (suggestedDistrict.isEmpty) {
      if (nearbyAsync.isLoading) return const LoadingSkeleton(count: 3);
      return EmptyStateCard(
        icon: Icons.map_rounded,
        title: loc.noDistrictYetTitle,
        subtitle: loc.noDistrictYetMsg,
      );
    }

    final districtAsync = ref.watch(districtAlertsProvider(suggestedDistrict));

    return districtAsync.when(
      loading: () => const LoadingSkeleton(count: 3),
      error: (e, _) => RetryCard(
        error: e,
        onRetry: () =>
            ref.invalidate(districtAlertsProvider(suggestedDistrict)),
      ),
      data: (all) {
        var result = filter.apply(all);
        result = result
            .where((a) => matchesQuery(
                query, [a.title, a.disease, a.village, a.district]))
            .toList();
        return _AlertList(
          alerts: result,
          lat: lat,
          lng: lng,
          tab: AlertDashboardTab.district,
          loc: loc,
          hasActiveFilters: filter.hasActiveFilters || query.trim().isNotEmpty,
          districtLabel: suggestedDistrict,
        );
      },
    );
  }
}

class _AlertList extends StatelessWidget {
  final List<DiseaseAlertModel> alerts;
  final double lat, lng;
  final AlertDashboardTab tab;
  final bool hasActiveFilters;
  final String? districtLabel;
  final AppLocalizations loc;

  const _AlertList({
    required this.alerts,
    required this.lat,
    required this.lng,
    required this.tab,
    required this.hasActiveFilters,
    required this.loc,
    this.districtLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return EmptyStateCard(
        icon: tab == AlertDashboardTab.active
            ? Icons.check_circle_outline_rounded
            : Icons.search_off_rounded,
        title: tab == AlertDashboardTab.active
            ? loc.noUrgentAlertsTitle
            : loc.noAlertsFoundTitle,
        subtitle: hasActiveFilters
            ? loc.tryRemovingFiltersMsg
            : districtLabel != null
                ? loc.noActiveAlertsInDistrictMsg(districtLabel!)
                : loc.noActiveAlertsMsg,
        accentColor: tab == AlertDashboardTab.active && !hasActiveFilters
            ? AppColors.success
            : null,
      );
    }
    return ResponsiveCenter(
      child: ListView.separated(
        padding: AppSpacing.screenPadding,
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          final alert = alerts[i];
          return AlertCard(
            alert: alert,
            distanceKm:
                GeoHashHelper.distanceKm(lat, lng, alert.lat, alert.lng),
            onReadMore: () =>
                context.push(RouteConstants.alertDetail(alert.id)),
          );
        },
      ),
    );
  }
}
