import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/farm_model.dart';
import 'package:jeevamitra/presentation/screens/shepherd/discover/discover_filter.dart';

FarmModel _farm({
  required String id,
  double lat = 16.3067,
  double lng = 80.4365,
  bool isAvailable = true,
  DateTime? createdAt,
  double areaSqMeters = 4000,
  double pricePerDayPerAnimal = 15,
  List<String> fodderTypes = const [],
  bool hasWater = false,
  bool hasShade = false,
  bool hasFencing = false,
  String village = 'Narasaraopet',
  String district = 'Guntur',
}) {
  return FarmModel(
    id: id,
    ownerId: 'owner-1',
    ownerName: 'Farmer Ravi',
    title: 'Farm $id',
    description: 'desc',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    village: village,
    district: district,
    state: 'Andhra Pradesh',
    areaSqMeters: areaSqMeters,
    areaUnit: 'acre',
    fodderTypes: fodderTypes,
    pricePerDayPerAnimal: pricePerDayPerAnimal,
    maxAnimals: 100,
    hasWater: hasWater,
    hasShade: hasShade,
    hasFencing: hasFencing,
    isAvailable: isAvailable,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  const originLat = 16.3067, originLng = 80.4365;

  group('rankFarms', () {
    test('closest sorts by ascending distance', () {
      final near = _farm(id: 'near', lat: originLat + 0.01, lng: originLng);
      final far = _farm(id: 'far', lat: originLat + 1.0, lng: originLng);
      final ranked =
          rankFarms([far, near], originLat, originLng, DiscoverSortMode.closest);
      expect(ranked.map((r) => r.$1.id), ['near', 'far']);
      expect(ranked.first.$2, lessThan(ranked.last.$2));
    });

    test('available groups available farms first, closest within each group', () {
      final farUnavailable =
          _farm(id: 'far-unavail', lat: originLat + 0.01, lng: originLng, isAvailable: false);
      final nearAvailable =
          _farm(id: 'near-avail', lat: originLat + 0.5, lng: originLng, isAvailable: true);
      final ranked = rankFarms(
          [farUnavailable, nearAvailable], originLat, originLng, DiscoverSortMode.available);
      expect(ranked.first.$1.id, 'near-avail');
      expect(ranked.first.$1.isAvailable, isTrue);
    });

    test('newest sorts by createdAt descending', () {
      final old = _farm(id: 'old', createdAt: DateTime(2025, 1, 1));
      final recent = _farm(id: 'recent', createdAt: DateTime(2026, 6, 1));
      final ranked = rankFarms([old, recent], originLat, originLng, DiscoverSortMode.newest);
      expect(ranked.map((r) => r.$1.id), ['recent', 'old']);
    });

    test('distance is computed with GeoHashHelper.distanceKm (matches repository filtering)',
        () {
      final farm = _farm(id: 'x', lat: originLat + 0.018, lng: originLng);
      final ranked = rankFarms([farm], originLat, originLng, DiscoverSortMode.closest);
      final expected = GeoHashHelper.distanceKm(originLat, originLng, farm.lat, farm.lng);
      expect(ranked.first.$2, expected);
    });
  });

  group('DiscoverFilterState.apply', () {
    test('excludes unavailable farms by default', () {
      final farms = [_farm(id: 'a', isAvailable: true), _farm(id: 'b', isAvailable: false)];
      const filter = DiscoverFilterState();
      expect(filter.apply(farms).map((f) => f.id), ['a']);
    });

    test('includeUnavailable: true lets unavailable farms through', () {
      final farms = [_farm(id: 'a', isAvailable: true), _farm(id: 'b', isAvailable: false)];
      const filter = DiscoverFilterState(includeUnavailable: true);
      expect(filter.apply(farms).map((f) => f.id), containsAll(['a', 'b']));
    });

    test('filters by max price', () {
      final farms = [
        _farm(id: 'cheap', pricePerDayPerAnimal: 10),
        _farm(id: 'pricey', pricePerDayPerAnimal: 100),
      ];
      const filter = DiscoverFilterState(maxPricePerDay: 50);
      expect(filter.apply(farms).map((f) => f.id), ['cheap']);
    });

    test('filters by acre range', () {
      // 4046.856 sqm per acre
      final farms = [
        _farm(id: 'small', areaSqMeters: 1 * 4046.856),
        _farm(id: 'medium', areaSqMeters: 5 * 4046.856),
        _farm(id: 'large', areaSqMeters: 20 * 4046.856),
      ];
      const filter = DiscoverFilterState(minAcres: 3, maxAcres: 10);
      expect(filter.apply(farms).map((f) => f.id), ['medium']);
    });

    test('filters by village substring, case-insensitive', () {
      final farms = [
        _farm(id: 'a', village: 'Narasaraopet'),
        _farm(id: 'b', village: 'Guntur City'),
      ];
      const filter = DiscoverFilterState(village: 'narasa');
      expect(filter.apply(farms).map((f) => f.id), ['a']);
    });

    test('filters by district substring, case-insensitive', () {
      final farms = [_farm(id: 'a', district: 'Guntur'), _farm(id: 'b', district: 'Krishna')];
      const filter = DiscoverFilterState(district: 'GUNTUR');
      expect(filter.apply(farms).map((f) => f.id), ['a']);
    });

    test('filters by amenities', () {
      final farms = [
        _farm(id: 'has-water', hasWater: true),
        _farm(id: 'no-water', hasWater: false),
      ];
      const filter = DiscoverFilterState(onlyWater: true);
      expect(filter.apply(farms).map((f) => f.id), ['has-water']);
    });

    test('filters by fodder type', () {
      final farms = [
        _farm(id: 'grass', fodderTypes: const ['grass']),
        _farm(id: 'maize', fodderTypes: const ['maize']),
      ];
      const filter = DiscoverFilterState(fodderTypes: ['grass']);
      expect(filter.apply(farms).map((f) => f.id), ['grass']);
    });

    test('hasActiveFilters is false for the default state', () {
      expect(const DiscoverFilterState().hasActiveFilters, isFalse);
    });

    test('hasActiveFilters is true once any filter is set', () {
      expect(const DiscoverFilterState(includeUnavailable: true).hasActiveFilters, isTrue);
      expect(const DiscoverFilterState(village: 'x').hasActiveFilters, isTrue);
      expect(const DiscoverFilterState(maxPricePerDay: 10).hasActiveFilters, isTrue);
    });

    test('copyWith clearMaxPrice actually clears rather than requiring a new value', () {
      const withPrice = DiscoverFilterState(maxPricePerDay: 100);
      final cleared = withPrice.copyWith(clearMaxPrice: true);
      expect(cleared.maxPricePerDay, isNull);
    });
  });
}
