import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/farm_model.dart';
import 'package:jeevamitra/data/models/vet_model.dart';
import 'package:jeevamitra/presentation/screens/shepherd/explore_map/unified_explore_filter.dart';

FarmModel _farm({String title = 'Green Pasture', String village = 'Narasaraopet', String district = 'Guntur'}) {
  const lat = 16.3, lng = 80.4;
  return FarmModel(
    id: 'farm-1',
    ownerId: 'owner-1',
    ownerName: 'Farmer Ravi',
    title: title,
    description: '',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    village: village,
    district: district,
    state: 'Andhra Pradesh',
    areaSqMeters: 4000,
    areaUnit: 'acre',
    fodderTypes: const [],
    pricePerDayPerAnimal: 15,
    maxAnimals: 100,
    createdAt: DateTime(2026, 1, 1),
  );
}

VetModel _vet({String name = 'Dr. Lakshmi', String village = 'Narasaraopet', String district = 'Guntur'}) {
  const lat = 16.3, lng = 80.4;
  return VetModel(
    id: 'vet-1',
    name: name,
    qualification: 'BVSc',
    specialization: '',
    phone: '9999999999',
    village: village,
    district: district,
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
  );
}

void main() {
  group('UnifiedExploreFilter', () {
    test('with no query, matches everything (subject to showLands/showVets)', () {
      const filter = UnifiedExploreFilter();
      expect(filter.matchesFarm(_farm()), isTrue);
      expect(filter.matchesVet(_vet()), isTrue);
    });

    test('showLands: false excludes all farms regardless of query', () {
      const filter = UnifiedExploreFilter(showLands: false);
      expect(filter.matchesFarm(_farm()), isFalse);
    });

    test('showVets: false excludes all vets regardless of query', () {
      const filter = UnifiedExploreFilter(showVets: false);
      expect(filter.matchesVet(_vet()), isFalse);
    });

    test('query matches a land by title, case-insensitive', () {
      const filter = UnifiedExploreFilter(query: 'green');
      expect(filter.matchesFarm(_farm(title: 'Green Pasture')), isTrue);
      expect(filter.matchesFarm(_farm(title: 'Blue Meadow')), isFalse);
    });

    test('query matches a vet by name, case-insensitive', () {
      const filter = UnifiedExploreFilter(query: 'LAKSHMI');
      expect(filter.matchesVet(_vet(name: 'Dr. Lakshmi')), isTrue);
      expect(filter.matchesVet(_vet(name: 'Dr. Rao')), isFalse);
    });

    test('query matches by village for both farms and vets', () {
      const filter = UnifiedExploreFilter(query: 'narasa');
      expect(filter.matchesFarm(_farm(village: 'Narasaraopet')), isTrue);
      expect(filter.matchesVet(_vet(village: 'Narasaraopet')), isTrue);
      expect(filter.matchesFarm(_farm(village: 'Vijayawada')), isFalse);
    });

    test('query matches by district for both farms and vets', () {
      const filter = UnifiedExploreFilter(query: 'guntur');
      expect(filter.matchesFarm(_farm(district: 'Guntur')), isTrue);
      expect(filter.matchesVet(_vet(district: 'Guntur')), isTrue);
    });

    test('applyToFarms and applyToVets filter lists consistently with the matchers', () {
      const filter = UnifiedExploreFilter(query: 'green');
      final farms = [_farm(title: 'Green Pasture'), _farm(title: 'Blue Meadow')];
      expect(filter.applyToFarms(farms).map((f) => f.title), ['Green Pasture']);
    });

    test('hasQuery reflects whether a non-blank query is set', () {
      expect(const UnifiedExploreFilter().hasQuery, isFalse);
      expect(const UnifiedExploreFilter(query: '   ').hasQuery, isFalse);
      expect(const UnifiedExploreFilter(query: 'x').hasQuery, isTrue);
    });

    test('copyWith preserves unspecified fields', () {
      const original = UnifiedExploreFilter(radiusKm: 50, query: 'x', showVets: false);
      final updated = original.copyWith(query: 'y');
      expect(updated.radiusKm, 50);
      expect(updated.query, 'y');
      expect(updated.showVets, isFalse);
    });
  });
}
