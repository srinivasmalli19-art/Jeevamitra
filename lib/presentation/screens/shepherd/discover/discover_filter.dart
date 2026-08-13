import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../core/utils/search_matcher.dart';
import '../../../../data/models/farm_model.dart';

/// Sort mode for the Nearby Lands list. [closest] (distance ascending) is
/// the default; [available] groups available lands first, closest within
/// each group; [newest] sorts by listing creation date, most recent first.
enum DiscoverSortMode { closest, available, newest }

/// A farm paired with its distance from the shepherd, computed once via
/// [GeoHashHelper.distanceKm] — the same Haversine formula
/// `FarmRepository.watchNearby` already uses for radius filtering/sorting,
/// so a card's displayed distance can never disagree with the backing
/// query's notion of "closest".
typedef RankedFarm = (FarmModel farm, double distanceKm);

List<RankedFarm> rankFarms(
  List<FarmModel> farms,
  double lat,
  double lng,
  DiscoverSortMode sort,
) {
  final ranked = farms.map((f) => (f, GeoHashHelper.distanceKm(lat, lng, f.lat, f.lng))).toList();
  switch (sort) {
    case DiscoverSortMode.closest:
      ranked.sort((a, b) => a.$2.compareTo(b.$2));
    case DiscoverSortMode.available:
      ranked.sort((a, b) {
        if (a.$1.isAvailable != b.$1.isAvailable) {
          return a.$1.isAvailable ? -1 : 1;
        }
        return a.$2.compareTo(b.$2);
      });
    case DiscoverSortMode.newest:
      ranked.sort((a, b) => b.$1.createdAt.compareTo(a.$1.createdAt));
  }
  return ranked;
}

/// Client-side filter state for Nearby Lands discovery. [radiusKm] is
/// applied at the Firestore query level (FarmRepository.watchNearby);
/// everything else here is applied to the query's results, matching the
/// pattern already established for fodder/amenity/price filtering.
class DiscoverFilterState {
  final double radiusKm;
  final List<String> fodderTypes;
  final bool onlyWater;
  final bool onlyShade;
  final bool onlyFencing;
  final double? maxPricePerDay;
  final double? minAcres;
  final double? maxAcres;
  final bool includeUnavailable;
  final String village;
  final String district;

  const DiscoverFilterState({
    this.radiusKm = 50,
    this.fodderTypes = const [],
    this.onlyWater = false,
    this.onlyShade = false,
    this.onlyFencing = false,
    this.maxPricePerDay,
    this.minAcres,
    this.maxAcres,
    this.includeUnavailable = false,
    this.village = '',
    this.district = '',
  });

  DiscoverFilterState copyWith({
    double? radiusKm,
    List<String>? fodderTypes,
    bool? onlyWater,
    bool? onlyShade,
    bool? onlyFencing,
    double? maxPricePerDay,
    bool clearMaxPrice = false,
    double? minAcres,
    bool clearMinAcres = false,
    double? maxAcres,
    bool clearMaxAcres = false,
    bool? includeUnavailable,
    String? village,
    String? district,
  }) =>
      DiscoverFilterState(
        radiusKm: radiusKm ?? this.radiusKm,
        fodderTypes: fodderTypes ?? this.fodderTypes,
        onlyWater: onlyWater ?? this.onlyWater,
        onlyShade: onlyShade ?? this.onlyShade,
        onlyFencing: onlyFencing ?? this.onlyFencing,
        maxPricePerDay: clearMaxPrice ? null : (maxPricePerDay ?? this.maxPricePerDay),
        minAcres: clearMinAcres ? null : (minAcres ?? this.minAcres),
        maxAcres: clearMaxAcres ? null : (maxAcres ?? this.maxAcres),
        includeUnavailable: includeUnavailable ?? this.includeUnavailable,
        village: village ?? this.village,
        district: district ?? this.district,
      );

  bool get hasActiveFilters =>
      fodderTypes.isNotEmpty ||
      onlyWater ||
      onlyShade ||
      onlyFencing ||
      maxPricePerDay != null ||
      minAcres != null ||
      maxAcres != null ||
      includeUnavailable ||
      village.trim().isNotEmpty ||
      district.trim().isNotEmpty;

  List<FarmModel> apply(List<FarmModel> farms) {
    return farms.where((f) {
      if (!includeUnavailable && !f.isAvailable) return false;
      if (fodderTypes.isNotEmpty && !fodderTypes.any((t) => f.fodderTypes.contains(t))) {
        return false;
      }
      if (onlyWater && !f.hasWater) return false;
      if (onlyShade && !f.hasShade) return false;
      if (onlyFencing && !f.hasFencing) return false;
      if (maxPricePerDay != null && f.pricePerDayPerAnimal > maxPricePerDay!) return false;
      if (minAcres != null && f.areaInAcres < minAcres!) return false;
      if (maxAcres != null && f.areaInAcres > maxAcres!) return false;
      if (village.trim().isNotEmpty && !matchesQuery(village, [f.village])) {
        return false;
      }
      if (district.trim().isNotEmpty && !matchesQuery(district, [f.district])) {
        return false;
      }
      return true;
    }).toList();
  }
}
