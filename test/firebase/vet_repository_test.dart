// Veterinary Booking + Map coverage: vet discovery uses the same geohash
// nearby-search technique as farm discovery.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/vet_model.dart';
import 'package:jeevamitra/data/repositories/vet_repository.dart';

VetModel _vet({required String id, required double lat, required double lng, double rating = 4.0}) {
  return VetModel(
    id: id,
    name: 'Dr. Lakshmi',
    qualification: 'BVSc',
    specialization: 'Livestock',
    phone: '+919876500000',
    village: 'Narasaraopet',
    district: 'Guntur',
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    rating: rating,
    isVerified: true,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late VetRepository repo;

  const originLat = 16.3067;
  const originLng = 80.4365;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = VetRepository(firestore: firestore);
  });

  group('watchNearby', () {
    test('returns vets within the radius, closest first', () async {
      // Both points must stay within the same coarse geohash prefix cell
      // that watchNearby's range query uses at radiusKm:50 (precision 4,
      // tens-of-km cells) — a far-but-still-in-radius point risks crossing
      // a cell boundary and being missed by the prefix query entirely,
      // which is a real (documented) geohash range-query limitation, not
      // something this test should assert against.
      await firestore.collection('vets').add(_vet(id: 'far', lat: originLat + 0.03, lng: originLng).toFirestore());
      await firestore.collection('vets').add(_vet(id: 'near', lat: originLat + 0.01, lng: originLng).toFirestore());

      final results = await repo.watchNearby(lat: originLat, lng: originLng, radiusKm: 50).first;

      expect(results, hasLength(2));
      expect(results.first.name, 'Dr. Lakshmi');
      // "near" (smaller lat delta) must sort before "far".
      final distances = results
          .map((v) => GeoHashHelper.distanceKm(originLat, originLng, v.lat, v.lng))
          .toList();
      expect(distances, orderedEquals([...distances]..sort()));
    });

    test('excludes vets outside the radius entirely', () async {
      await firestore.collection('vets').add(_vet(id: 'far', lat: originLat + 5, lng: originLng).toFirestore());

      final results = await repo.watchNearby(lat: originLat, lng: originLng, radiusKm: 20).first;
      expect(results, isEmpty);
    });
  });

  group('watchVet', () {
    test('streams a single vet document by id', () async {
      final ref = await firestore.collection('vets').add(_vet(id: 'x', lat: originLat, lng: originLng).toFirestore());
      final vet = await repo.watchVet(ref.id).first;
      expect(vet, isNotNull);
      expect(vet!.name, 'Dr. Lakshmi');
    });

    test('returns null for a non-existent vet id', () async {
      final vet = await repo.watchVet('does-not-exist').first;
      expect(vet, isNull);
    });
  });
}
