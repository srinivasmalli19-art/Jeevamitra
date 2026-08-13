import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../core/utils/search_matcher.dart';
import '../../../../data/models/disease_alert_model.dart';
import '../../../../data/models/farm_model.dart';
import '../../../../data/models/vet_model.dart';
import '../../../../generated/l10n/app_localizations.dart';

enum SearchResultCategory { land, vet, alert, village, district }

extension SearchResultCategoryX on SearchResultCategory {
  /// Localized display label. Needs [loc] since this is a `switch` over an
  /// enum, not a `const` value — unlike [AlertSeverity.label], nothing here
  /// is baked in at compile time, so this reads the current locale fresh
  /// on every call.
  String labelFor(AppLocalizations loc) => switch (this) {
        SearchResultCategory.land => loc.categoryLandLabel,
        SearchResultCategory.vet => loc.categoryVetLabel,
        SearchResultCategory.alert => loc.categoryAlertLabel,
        SearchResultCategory.village => loc.categoryVillageLabel,
        SearchResultCategory.district => loc.categoryDistrictLabel,
      };

  Color get color => switch (this) {
        SearchResultCategory.land => AppColors.primary,
        SearchResultCategory.vet => AppColors.info,
        SearchResultCategory.alert => AppColors.error,
        SearchResultCategory.village => AppColors.secondary,
        SearchResultCategory.district => AppColors.secondaryDark,
      };

  IconData get icon => switch (this) {
        SearchResultCategory.land => Icons.landscape_rounded,
        SearchResultCategory.vet => Icons.medical_services_rounded,
        SearchResultCategory.alert => Icons.coronavirus_rounded,
        SearchResultCategory.village => Icons.holiday_village_rounded,
        SearchResultCategory.district => Icons.map_rounded,
      };
}

/// One row in the unified search results list. [id] is the underlying
/// document id for [land]/[vet]/[alert] results, or the place name itself
/// for [village]/[district] results (which have no document of their own).
class SearchResultItem {
  final SearchResultCategory category;
  final String id;
  final String title;
  final String subtitle;
  final double distanceKm;

  const SearchResultItem({
    required this.category,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.distanceKm,
  });
}

/// Builds the unified result list from already-fetched farms, vets, and
/// alerts — this performs zero Firestore reads of its own. Villages and
/// Districts aren't a collection: each distinct name found across farms
/// and vets is folded into a single result (first match wins), borrowing
/// that match's coordinate so a distance can still be shown.
///
/// A single pass per category, one shared [matchesQuery] call per
/// candidate — no field is matched twice and no result list is filtered
/// more than once.
List<SearchResultItem> buildSearchResults({
  required String query,
  required double userLat,
  required double userLng,
  required List<FarmModel> farms,
  required List<VetModel> vets,
  required List<DiseaseAlertModel> alerts,
}) {
  if (query.trim().isEmpty) return const [];

  double distTo(double lat, double lng) =>
      GeoHashHelper.distanceKm(userLat, userLng, lat, lng);

  final results = <SearchResultItem>[];

  for (final f in farms) {
    if (matchesQuery(query, [f.title, f.village, f.district])) {
      results.add(SearchResultItem(
        category: SearchResultCategory.land,
        id: f.id,
        title: f.title,
        subtitle: '${f.village}, ${f.district}',
        distanceKm: distTo(f.lat, f.lng),
      ));
    }
  }

  for (final v in vets) {
    if (matchesQuery(query, [v.name, v.village, v.district, v.specialization])) {
      results.add(SearchResultItem(
        category: SearchResultCategory.vet,
        id: v.id,
        title: v.name,
        subtitle: '${v.specialization} · ${v.village}, ${v.district}',
        distanceKm: distTo(v.lat, v.lng),
      ));
    }
  }

  for (final a in alerts) {
    if (matchesQuery(query, [a.title, a.disease, a.affectedSpecies, a.village, a.district])) {
      results.add(SearchResultItem(
        category: SearchResultCategory.alert,
        id: a.id,
        title: a.title,
        subtitle: '${a.disease} · ${a.district}, ${a.state}',
        distanceKm: distTo(a.lat, a.lng),
      ));
    }
  }

  final seenVillages = <String>{};
  final seenDistricts = <String>{};
  final places = [
    ...farms.map((f) => (
          village: f.village,
          district: f.district,
          state: f.state,
          lat: f.lat,
          lng: f.lng,
        )),
    ...vets.map((v) => (
          village: v.village,
          district: v.district,
          state: v.state,
          lat: v.lat,
          lng: v.lng,
        )),
    ...alerts.map((a) => (
          village: a.village,
          district: a.district,
          state: a.state,
          lat: a.lat,
          lng: a.lng,
        )),
  ];
  for (final p in places) {
    if (p.village.isNotEmpty && seenVillages.add(p.village)) {
      if (matchesQuery(query, [p.village])) {
        results.add(SearchResultItem(
          category: SearchResultCategory.village,
          id: p.village,
          title: p.village,
          subtitle: '${p.district}, ${p.state}',
          distanceKm: distTo(p.lat, p.lng),
        ));
      }
    }
    if (p.district.isNotEmpty && seenDistricts.add(p.district)) {
      if (matchesQuery(query, [p.district])) {
        results.add(SearchResultItem(
          category: SearchResultCategory.district,
          id: p.district,
          title: p.district,
          subtitle: p.state,
          distanceKm: distTo(p.lat, p.lng),
        ));
      }
    }
  }

  results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return results;
}
