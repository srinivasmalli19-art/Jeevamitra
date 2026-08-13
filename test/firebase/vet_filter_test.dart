import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/vet_model.dart';
import 'package:jeevamitra/presentation/screens/shepherd/vets/vet_filter.dart';

VetModel _vet({
  required String id,
  double lat = 16.3067,
  double lng = 80.4365,
  double rating = 0,
  int yearsOfExperience = 0,
  bool isAvailable24x7 = false,
  bool isGovtVet = false,
  double? consultationFee,
  String village = 'Narasaraopet',
  String district = 'Guntur',
  List<String> languages = const [],
  String specialization = '',
}) {
  return VetModel(
    id: id,
    name: 'Dr. $id',
    qualification: 'BVSc',
    specialization: specialization,
    phone: '9999999999',
    village: village,
    district: district,
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    isGovtVet: isGovtVet,
    isAvailable24x7: isAvailable24x7,
    consultationFee: consultationFee,
    rating: rating,
    yearsOfExperience: yearsOfExperience,
    languages: languages,
  );
}

void main() {
  const originLat = 16.3067, originLng = 80.4365;

  group('rankVets', () {
    test('closest sorts by ascending distance', () {
      final near = _vet(id: 'near', lat: originLat + 0.01, lng: originLng);
      final far = _vet(id: 'far', lat: originLat + 1.0, lng: originLng);
      final ranked = rankVets([far, near], originLat, originLng, VetSortMode.closest);
      expect(ranked.map((r) => r.$1.id), ['near', 'far']);
    });

    test('highestRated sorts by rating descending', () {
      final low = _vet(id: 'low', rating: 2.0);
      final high = _vet(id: 'high', rating: 4.8);
      final ranked = rankVets([low, high], originLat, originLng, VetSortMode.highestRated);
      expect(ranked.map((r) => r.$1.id), ['high', 'low']);
    });

    test('mostExperienced sorts by years of experience descending', () {
      final junior = _vet(id: 'junior', yearsOfExperience: 2);
      final senior = _vet(id: 'senior', yearsOfExperience: 20);
      final ranked =
          rankVets([junior, senior], originLat, originLng, VetSortMode.mostExperienced);
      expect(ranked.map((r) => r.$1.id), ['senior', 'junior']);
    });

    test('availableToday groups available-24x7 vets first, closest within each group', () {
      final farAvailable =
          _vet(id: 'far-avail', lat: originLat + 0.5, lng: originLng, isAvailable24x7: true);
      final nearUnavailable =
          _vet(id: 'near-unavail', lat: originLat + 0.01, lng: originLng, isAvailable24x7: false);
      final ranked = rankVets(
          [nearUnavailable, farAvailable], originLat, originLng, VetSortMode.availableToday);
      expect(ranked.first.$1.id, 'far-avail');
      expect(ranked.first.$1.isAvailable24x7, isTrue);
    });
  });

  group('VetFilterState.apply', () {
    test('filters by government-only', () {
      final vets = [_vet(id: 'govt', isGovtVet: true), _vet(id: 'private', isGovtVet: false)];
      const filter = VetFilterState(onlyGovt: true);
      expect(filter.apply(vets).map((v) => v.id), ['govt']);
    });

    test('filters by available today', () {
      final vets = [
        _vet(id: 'avail', isAvailable24x7: true),
        _vet(id: 'not-avail', isAvailable24x7: false),
      ];
      const filter = VetFilterState(onlyAvailableToday: true);
      expect(filter.apply(vets).map((v) => v.id), ['avail']);
    });

    test('filters by free consultation', () {
      final vets = [
        _vet(id: 'free', consultationFee: null),
        _vet(id: 'paid', consultationFee: 200),
      ];
      const filter = VetFilterState(onlyFree: true);
      expect(filter.apply(vets).map((v) => v.id), ['free']);
    });

    test('filters by minimum rating', () {
      final vets = [_vet(id: 'low', rating: 2.5), _vet(id: 'high', rating: 4.5)];
      const filter = VetFilterState(minRating: 4.0);
      expect(filter.apply(vets).map((v) => v.id), ['high']);
    });

    test('filters by minimum experience', () {
      final vets = [
        _vet(id: 'junior', yearsOfExperience: 1),
        _vet(id: 'senior', yearsOfExperience: 15),
      ];
      const filter = VetFilterState(minExperience: 10);
      expect(filter.apply(vets).map((v) => v.id), ['senior']);
    });

    test('filters by village substring, case-insensitive', () {
      final vets = [
        _vet(id: 'a', village: 'Narasaraopet'),
        _vet(id: 'b', village: 'Guntur City'),
      ];
      const filter = VetFilterState(village: 'narasa');
      expect(filter.apply(vets).map((v) => v.id), ['a']);
    });

    test('filters by district substring, case-insensitive', () {
      final vets = [_vet(id: 'a', district: 'Guntur'), _vet(id: 'b', district: 'Krishna')];
      const filter = VetFilterState(district: 'GUNTUR');
      expect(filter.apply(vets).map((v) => v.id), ['a']);
    });

    test('filters by language', () {
      final vets = [
        _vet(id: 'telugu', languages: const ['Telugu']),
        _vet(id: 'hindi', languages: const ['Hindi']),
      ];
      const filter = VetFilterState(language: 'Telugu');
      expect(filter.apply(vets).map((v) => v.id), ['telugu']);
    });

    test('filters by specialization', () {
      final vets = [
        _vet(id: 'surgery', specialization: 'Surgery'),
        _vet(id: 'poultry', specialization: 'Poultry'),
      ];
      const filter = VetFilterState(specialization: 'Surgery');
      expect(filter.apply(vets).map((v) => v.id), ['surgery']);
    });

    test('hasActiveFilters is false for the default state', () {
      expect(const VetFilterState().hasActiveFilters, isFalse);
    });

    test('hasActiveFilters is true once any filter is set', () {
      expect(const VetFilterState(minRating: 3).hasActiveFilters, isTrue);
      expect(const VetFilterState(language: 'Telugu').hasActiveFilters, isTrue);
    });

    test('copyWith clearLanguage/clearSpecialization actually clear', () {
      const withBoth = VetFilterState(language: 'Telugu', specialization: 'Surgery');
      final cleared = withBoth.copyWith(clearLanguage: true, clearSpecialization: true);
      expect(cleared.language, isNull);
      expect(cleared.specialization, isNull);
    });
  });
}
