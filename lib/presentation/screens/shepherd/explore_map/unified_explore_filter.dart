import '../../../../core/utils/search_matcher.dart';
import '../../../../data/models/farm_model.dart';
import '../../../../data/models/vet_model.dart';

/// Filter state shared between the Explore map view and its list view —
/// the same [UnifiedExploreFilter] instance drives both, so switching
/// views can never show a farm or vet that the other view would have
/// excluded. Search matches land title, vet name, village, or district.
class UnifiedExploreFilter {
  final double radiusKm;
  final String query;
  final bool showLands;
  final bool showVets;

  const UnifiedExploreFilter({
    this.radiusKm = 25,
    this.query = '',
    this.showLands = true,
    this.showVets = true,
  });

  UnifiedExploreFilter copyWith({
    double? radiusKm,
    String? query,
    bool? showLands,
    bool? showVets,
  }) =>
      UnifiedExploreFilter(
        radiusKm: radiusKm ?? this.radiusKm,
        query: query ?? this.query,
        showLands: showLands ?? this.showLands,
        showVets: showVets ?? this.showVets,
      );

  bool get hasQuery => query.trim().isNotEmpty;

  bool matchesFarm(FarmModel farm) {
    if (!showLands) return false;
    return matchesQuery(query, [farm.title, farm.village, farm.district]);
  }

  bool matchesVet(VetModel vet) {
    if (!showVets) return false;
    return matchesQuery(query, [vet.name, vet.village, vet.district]);
  }

  List<FarmModel> applyToFarms(List<FarmModel> farms) => farms.where(matchesFarm).toList();

  List<VetModel> applyToVets(List<VetModel> vets) => vets.where(matchesVet).toList();
}
