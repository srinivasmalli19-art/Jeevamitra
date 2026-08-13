import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/disease_alert_model.dart';
import 'package:jeevamitra/data/models/farm_model.dart';
import 'package:jeevamitra/data/models/vet_model.dart';
import 'package:jeevamitra/presentation/screens/shared/search/search_result.dart';

const _originLat = 16.3067, _originLng = 80.4365;

FarmModel _farm({
  required String id,
  String title = 'Green Pasture',
  String village = 'Narasaraopet',
  String district = 'Guntur',
  double lat = _originLat,
  double lng = _originLng,
}) {
  return FarmModel(
    id: id,
    ownerId: 'owner-1',
    ownerName: 'Farmer Ravi',
    title: title,
    description: 'desc',
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

VetModel _vet({
  required String id,
  String name = 'Dr. Rao',
  String village = 'Narasaraopet',
  String district = 'Guntur',
  String specialization = 'Surgery',
  double lat = _originLat,
  double lng = _originLng,
}) {
  return VetModel(
    id: id,
    name: name,
    qualification: 'BVSc',
    specialization: specialization,
    phone: '9999999999',
    village: village,
    district: district,
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
  );
}

DiseaseAlertModel _alert({
  required String id,
  String title = 'PPR Outbreak',
  String disease = 'PPR',
  String affectedSpecies = 'sheep',
  String district = 'Guntur',
  double lat = _originLat,
  double lng = _originLng,
}) {
  return DiseaseAlertModel(
    id: id,
    title: title,
    description: 'desc',
    disease: disease,
    affectedSpecies: affectedSpecies,
    severity: 'high',
    district: district,
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    radiusKm: 50,
    sourceAuthority: 'AH Dept',
    issuedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('buildSearchResults', () {
    test('empty query returns no results', () {
      final results = buildSearchResults(
        query: '',
        userLat: _originLat,
        userLng: _originLng,
        farms: [_farm(id: 'f1')],
        vets: [_vet(id: 'v1')],
        alerts: [_alert(id: 'a1')],
      );
      expect(results, isEmpty);
    });

    test('matches a land by title, case-insensitive partial text', () {
      final results = buildSearchResults(
        query: 'pasture',
        userLat: _originLat,
        userLng: _originLng,
        farms: [_farm(id: 'f1', title: 'Green Pasture')],
        vets: const [],
        alerts: const [],
      );
      expect(results, hasLength(1));
      expect(results.first.category, SearchResultCategory.land);
      expect(results.first.id, 'f1');
    });

    test('matches a vet by name', () {
      // 'rao' also matches the default village fixture ("Narasaraopet"),
      // so this asserts on the vet result specifically rather than
      // asserting a single overall result.
      final results = buildSearchResults(
        query: 'rao',
        userLat: _originLat,
        userLng: _originLng,
        farms: const [],
        vets: [_vet(id: 'v1', name: 'Dr. Rao')],
        alerts: const [],
      );
      final vetResults = results.where((r) => r.category == SearchResultCategory.vet);
      expect(vetResults, hasLength(1));
      expect(vetResults.first.id, 'v1');
    });

    test('matches a disease alert by disease name', () {
      final results = buildSearchResults(
        query: 'ppr',
        userLat: _originLat,
        userLng: _originLng,
        farms: const [],
        vets: const [],
        alerts: [_alert(id: 'a1', disease: 'PPR')],
      );
      expect(results, hasLength(1));
      expect(results.first.category, SearchResultCategory.alert);
    });

    test('synthesizes a village result from farm/vet location data', () {
      final results = buildSearchResults(
        query: 'narasa',
        userLat: _originLat,
        userLng: _originLng,
        farms: [_farm(id: 'f1', title: 'Unrelated Title', village: 'Narasaraopet')],
        vets: const [],
        alerts: const [],
      );
      expect(results.any((r) => r.category == SearchResultCategory.village), isTrue);
      final village = results.firstWhere((r) => r.category == SearchResultCategory.village);
      expect(village.title, 'Narasaraopet');
    });

    test('synthesizes a district result from farm/vet location data', () {
      final results = buildSearchResults(
        query: 'guntur',
        userLat: _originLat,
        userLng: _originLng,
        farms: [_farm(id: 'f1', title: 'Unrelated Title', district: 'Guntur')],
        vets: const [],
        alerts: const [],
      );
      expect(results.any((r) => r.category == SearchResultCategory.district), isTrue);
    });

    test('deduplicates villages seen across multiple farms/vets', () {
      final results = buildSearchResults(
        query: 'narasa',
        userLat: _originLat,
        userLng: _originLng,
        farms: [
          _farm(id: 'f1', village: 'Narasaraopet'),
          _farm(id: 'f2', village: 'Narasaraopet'),
        ],
        vets: [_vet(id: 'v1', village: 'Narasaraopet')],
        alerts: const [],
      );
      expect(results.where((r) => r.category == SearchResultCategory.village), hasLength(1));
    });

    test('a query matching nothing returns an empty list', () {
      final results = buildSearchResults(
        query: 'xyzxyz',
        userLat: _originLat,
        userLng: _originLng,
        farms: [_farm(id: 'f1')],
        vets: [_vet(id: 'v1')],
        alerts: [_alert(id: 'a1')],
      );
      expect(results, isEmpty);
    });

    test('results are sorted by distance ascending', () {
      final results = buildSearchResults(
        query: 'guntur',
        userLat: _originLat,
        userLng: _originLng,
        farms: [
          _farm(id: 'far', title: 'Far Guntur Land', lat: _originLat + 1.0, lng: _originLng),
          _farm(id: 'near', title: 'Near Guntur Land', lat: _originLat + 0.01, lng: _originLng),
        ],
        vets: const [],
        alerts: const [],
      );
      final lands = results.where((r) => r.category == SearchResultCategory.land).toList();
      expect(lands.first.id, 'near');
      expect(lands.first.distanceKm, lessThan(lands.last.distanceKm));
    });

    test('distance matches GeoHashHelper.distanceKm', () {
      final farm = _farm(id: 'f1', lat: _originLat + 0.02, lng: _originLng);
      final results = buildSearchResults(
        query: 'green',
        userLat: _originLat,
        userLng: _originLng,
        farms: [farm],
        vets: const [],
        alerts: const [],
      );
      final expected =
          GeoHashHelper.distanceKm(_originLat, _originLng, farm.lat, farm.lng);
      expect(results.first.distanceKm, expected);
    });
  });
}
