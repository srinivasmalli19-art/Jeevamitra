import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../core/utils/search_matcher.dart';
import '../../../../data/models/vet_model.dart';

/// Sort mode for Vets Nearby. [closest] (distance ascending) is the
/// default; [highestRated] sorts by rating descending; [mostExperienced]
/// by years of experience descending; [availableToday] groups
/// available-24x7 vets first, closest within each group.
enum VetSortMode { closest, highestRated, mostExperienced, availableToday }

/// A vet paired with its distance from the shepherd, computed once via
/// [GeoHashHelper.distanceKm] — the same Haversine formula
/// `VetRepository.watchNearby` already uses for radius filtering, so a
/// card's displayed distance can never disagree with the backing query.
typedef RankedVet = (VetModel vet, double distanceKm);

List<RankedVet> rankVets(List<VetModel> vets, double lat, double lng, VetSortMode sort) {
  final ranked = vets.map((v) => (v, GeoHashHelper.distanceKm(lat, lng, v.lat, v.lng))).toList();
  switch (sort) {
    case VetSortMode.closest:
      ranked.sort((a, b) => a.$2.compareTo(b.$2));
    case VetSortMode.highestRated:
      ranked.sort((a, b) => b.$1.rating.compareTo(a.$1.rating));
    case VetSortMode.mostExperienced:
      ranked.sort((a, b) => b.$1.yearsOfExperience.compareTo(a.$1.yearsOfExperience));
    case VetSortMode.availableToday:
      ranked.sort((a, b) {
        if (a.$1.isAvailable24x7 != b.$1.isAvailable24x7) {
          return a.$1.isAvailable24x7 ? -1 : 1;
        }
        return a.$2.compareTo(b.$2);
      });
  }
  return ranked;
}

/// Client-side filter state for Vets Nearby. [radiusKm] is applied at the
/// Firestore query level (VetRepository.watchNearby); everything else is
/// applied to the query's results, matching the pattern already
/// established for Nearby Lands (Batch 2B).
class VetFilterState {
  final double radiusKm;
  final bool onlyGovt;
  final bool onlyAvailableToday;
  final bool onlyFree;
  final double minRating;
  final int minExperience;
  final String village;
  final String district;
  final String? language;
  final String? specialization;

  const VetFilterState({
    this.radiusKm = 50,
    this.onlyGovt = false,
    this.onlyAvailableToday = false,
    this.onlyFree = false,
    this.minRating = 0,
    this.minExperience = 0,
    this.village = '',
    this.district = '',
    this.language,
    this.specialization,
  });

  VetFilterState copyWith({
    double? radiusKm,
    bool? onlyGovt,
    bool? onlyAvailableToday,
    bool? onlyFree,
    double? minRating,
    int? minExperience,
    String? village,
    String? district,
    String? language,
    bool clearLanguage = false,
    String? specialization,
    bool clearSpecialization = false,
  }) =>
      VetFilterState(
        radiusKm: radiusKm ?? this.radiusKm,
        onlyGovt: onlyGovt ?? this.onlyGovt,
        onlyAvailableToday: onlyAvailableToday ?? this.onlyAvailableToday,
        onlyFree: onlyFree ?? this.onlyFree,
        minRating: minRating ?? this.minRating,
        minExperience: minExperience ?? this.minExperience,
        village: village ?? this.village,
        district: district ?? this.district,
        language: clearLanguage ? null : (language ?? this.language),
        specialization: clearSpecialization ? null : (specialization ?? this.specialization),
      );

  bool get hasActiveFilters =>
      onlyGovt ||
      onlyAvailableToday ||
      onlyFree ||
      minRating > 0 ||
      minExperience > 0 ||
      village.trim().isNotEmpty ||
      district.trim().isNotEmpty ||
      language != null ||
      specialization != null;

  List<VetModel> apply(List<VetModel> vets) {
    return vets.where((v) {
      if (onlyGovt && !v.isGovtVet) return false;
      if (onlyAvailableToday && !v.isAvailable24x7) return false;
      if (onlyFree && !v.isFree) return false;
      if (minRating > 0 && v.rating < minRating) return false;
      if (minExperience > 0 && v.yearsOfExperience < minExperience) return false;
      if (village.trim().isNotEmpty && !matchesQuery(village, [v.village])) {
        return false;
      }
      if (district.trim().isNotEmpty && !matchesQuery(district, [v.district])) {
        return false;
      }
      if (language != null && !v.languages.contains(language)) return false;
      if (specialization != null && v.specialization != specialization) return false;
      return true;
    }).toList();
  }
}
