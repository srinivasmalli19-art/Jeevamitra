import '../../../../core/utils/search_matcher.dart';
import '../../../../data/models/disease_alert_model.dart';
import '../../../../generated/l10n/app_localizations.dart';
import 'alert_severity.dart';

/// The four lenses onto the same underlying alert data, per the Batch 2F
/// brief. All four are derived client-side from just two real streams
/// (`nearbyAlertsProvider`, `districtAlertsProvider`) — there is no
/// separate "active" or "recent" collection/query, since
/// `DiseaseAlertRepository` already only ever returns active,
/// non-expired alerts to any client.
enum AlertDashboardTab { nearby, district, active, recent }

extension AlertDashboardTabX on AlertDashboardTab {
  String labelFor(AppLocalizations loc) => switch (this) {
        AlertDashboardTab.nearby => loc.tabNearbyLabel,
        AlertDashboardTab.district => loc.tabDistrictLabel,
        AlertDashboardTab.active => loc.tabActiveLabel,
        AlertDashboardTab.recent => loc.tabRecentLabel,
      };
}

/// Client-side filter state for the alert dashboard's Advanced Filters
/// sheet. [radiusKm] is applied at the Firestore query level
/// (`DiseaseAlertRepository.watchNearby`); everything else is applied to
/// the query's results, matching the pattern already established for
/// Nearby Lands (`DiscoverFilterState`) and Vets Nearby (`VetFilterState`).
class AlertFilterState {
  final double radiusKm;
  final Set<String> severities; // empty = all
  final Set<String> species; // empty = all
  final String village;
  final String district;
  final DateTime? issuedFrom;
  final DateTime? issuedTo;

  const AlertFilterState({
    this.radiusKm = 100,
    this.severities = const {},
    this.species = const {},
    this.village = '',
    this.district = '',
    this.issuedFrom,
    this.issuedTo,
  });

  AlertFilterState copyWith({
    double? radiusKm,
    Set<String>? severities,
    Set<String>? species,
    String? village,
    String? district,
    DateTime? issuedFrom,
    bool clearIssuedFrom = false,
    DateTime? issuedTo,
    bool clearIssuedTo = false,
  }) =>
      AlertFilterState(
        radiusKm: radiusKm ?? this.radiusKm,
        severities: severities ?? this.severities,
        species: species ?? this.species,
        village: village ?? this.village,
        district: district ?? this.district,
        issuedFrom: clearIssuedFrom ? null : (issuedFrom ?? this.issuedFrom),
        issuedTo: clearIssuedTo ? null : (issuedTo ?? this.issuedTo),
      );

  bool get hasActiveFilters =>
      severities.isNotEmpty ||
      species.isNotEmpty ||
      village.trim().isNotEmpty ||
      district.trim().isNotEmpty ||
      issuedFrom != null ||
      issuedTo != null;

  List<DiseaseAlertModel> apply(List<DiseaseAlertModel> alerts) {
    return alerts.where((a) {
      if (severities.isNotEmpty && !severities.contains(a.severity)) return false;
      if (species.isNotEmpty && !species.contains(a.affectedSpecies)) return false;
      if (village.trim().isNotEmpty && !matchesQuery(village, [a.village])) return false;
      if (district.trim().isNotEmpty && !matchesQuery(district, [a.district])) return false;
      if (issuedFrom != null && a.issuedAt.isBefore(issuedFrom!)) return false;
      if (issuedTo != null && a.issuedAt.isAfter(issuedTo!)) return false;
      return true;
    }).toList();
  }
}

/// "Recent" lens: the same active alerts, re-ordered as a pure chronological
/// feed (most recently issued first) rather than severity-first.
List<DiseaseAlertModel> sortByRecent(List<DiseaseAlertModel> alerts) {
  final sorted = [...alerts];
  sorted.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  return sorted;
}

/// "Active" lens: since the repository never returns inactive/expired
/// alerts to begin with, "Active" is interpreted as the urgent subset a
/// shepherd/farmer needs to act on right now — high/critical severity,
/// severity-first.
List<DiseaseAlertModel> urgentOnly(List<DiseaseAlertModel> alerts) {
  final urgent =
      alerts.where((a) => a.severity == 'critical' || a.severity == 'high').toList();
  urgent.sort((a, b) => AlertSeverity.weight(a.severity).compareTo(AlertSeverity.weight(b.severity)));
  return urgent;
}
