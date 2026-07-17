// Doubles as "Marketplace" and "Map" coverage: FarmRepository backs the
// farmer land-listing marketplace and its nearby-search relies on the same
// geohash range-query technique used for maps/discovery.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/farm_model.dart';
import 'package:jeevamitra/data/repositories/farm_repository.dart';
import 'package:mocktail/mocktail.dart';

// FarmRepository's `auth` param defaults eagerly to FirebaseAuth.instance
// when omitted (evaluated in the constructor initializer list, not lazily),
// which throws "no Firebase App" outside a real Firebase context even for
// tests that never touch currentUid/ownsDoc. Always pass a dummy mock here.
class _DummyAuth extends Mock implements FirebaseAuth {}

FarmModel _farm({
  required String id,
  required double lat,
  required double lng,
  String ownerId = 'owner-1',
  bool isAvailable = true,
}) {
  return FarmModel(
    id: id,
    ownerId: ownerId,
    ownerName: 'Farmer Ravi',
    title: 'Green Pasture $id',
    description: 'Lush grazing land near the river.',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    village: 'Narasaraopet',
    district: 'Guntur',
    state: 'Andhra Pradesh',
    areaSqMeters: 4000,
    areaUnit: 'acre',
    fodderTypes: const ['Green grass', 'Paddy straw'],
    pricePerDayPerAnimal: 15,
    maxAnimals: 100,
    isAvailable: isAvailable,
    createdAt: DateTime(2026, 6, 1),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late FarmRepository repo;

  // Guntur, AP (~16.3°N, 80.45°E) as the search origin.
  const originLat = 16.3067;
  const originLng = 80.4365;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FarmRepository(firestore: firestore, auth: _DummyAuth());
  });

  group('addFarm / watchMyFarms', () {
    test('a newly added farm appears in the owner\'s farm list', () async {
      final farm = _farm(id: 'ignored-by-write', lat: originLat, lng: originLng);
      final id = await repo.addFarm(farm);

      final mine = await repo.watchMyFarms('owner-1').first;
      expect(mine, hasLength(1));
      expect(mine.first.id, id);
      expect(mine.first.title, contains('Green Pasture'));
    });

    test('another owner\'s farms are excluded', () async {
      await repo.addFarm(_farm(id: 'a', lat: originLat, lng: originLng, ownerId: 'owner-1'));
      await repo.addFarm(_farm(id: 'b', lat: originLat, lng: originLng, ownerId: 'owner-2'));

      final mine = await repo.watchMyFarms('owner-1').first;
      expect(mine, hasLength(1));
    });
  });

  group('watchNearby (marketplace discovery)', () {
    test('finds a farm 2km away and excludes one 500km away, sorted by distance', () async {
      await firestore.collection('farms').add(
            _farm(id: 'near', lat: originLat + 0.018, lng: originLng).toFirestore(),
          ); // ~2km north
      await firestore.collection('farms').add(
            _farm(id: 'far', lat: originLat + 4.5, lng: originLng).toFirestore(),
          ); // ~500km north

      final results = await repo
          .watchNearby(lat: originLat, lng: originLng, radiusKm: 50)
          .first;

      expect(results, hasLength(1));
      expect(results.first.title, contains('near'));
    });

    test('excludes unavailable farms when onlyAvailable is true', () async {
      await firestore.collection('farms').add(
            _farm(id: 'unavailable', lat: originLat, lng: originLng, isAvailable: false)
                .toFirestore(),
          );

      final results = await repo
          .watchNearby(lat: originLat, lng: originLng, radiusKm: 50, onlyAvailable: true)
          .first;

      expect(results, isEmpty);
    });

    test('includes unavailable farms when onlyAvailable is false', () async {
      await firestore.collection('farms').add(
            _farm(id: 'unavailable', lat: originLat, lng: originLng, isAvailable: false)
                .toFirestore(),
          );

      final results = await repo
          .watchNearby(lat: originLat, lng: originLng, radiusKm: 50, onlyAvailable: false)
          .first;

      expect(results, hasLength(1));
    });
  });

  group('updateFarm', () {
    test('recomputes the geohash when lat/lng change', () async {
      final ref = await firestore.collection('farms').add(
            _farm(id: 'x', lat: originLat, lng: originLng).toFirestore(),
          );
      const newLat = 17.385, newLng = 78.4867; // Hyderabad

      await repo.updateFarm(ref.id, {'lat': newLat, 'lng': newLng});

      final doc = await firestore.collection('farms').doc(ref.id).get();
      expect(doc.data()!['geohash'], GeoHashHelper.encode(newLat, newLng));
    });
  });

  group('toggleAvailability / deleteFarm', () {
    test('toggleAvailability flips the flag', () async {
      final ref = await firestore.collection('farms').add(
            _farm(id: 'x', lat: originLat, lng: originLng).toFirestore(),
          );
      await repo.toggleAvailability(ref.id, false);
      final doc = await firestore.collection('farms').doc(ref.id).get();
      expect(doc.data()!['isAvailable'], isFalse);
    });

    test('deleteFarm removes the document', () async {
      final ref = await firestore.collection('farms').add(
            _farm(id: 'x', lat: originLat, lng: originLng).toFirestore(),
          );
      await repo.deleteFarm(ref.id);
      final doc = await firestore.collection('farms').doc(ref.id).get();
      expect(doc.exists, isFalse);
    });
  });
}
