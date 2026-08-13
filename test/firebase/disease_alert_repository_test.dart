// Disease Alert repository coverage — mirrors the patterns already
// established in farm_repository_test.dart / vet_repository_test.dart.
// Previously this repository hardcoded `FirebaseFirestore.instance`
// directly (no injectable override), which is why it had no tests at all
// while Farm and Vet did — fixed alongside adding these tests.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/disease_alert_model.dart';
import 'package:jeevamitra/data/repositories/disease_alert_repository.dart';

DiseaseAlertModel _alert({
  required String id,
  required double lat,
  required double lng,
  String severity = 'medium',
  String district = 'Guntur',
  bool isActive = true,
  DateTime? issuedAt,
  DateTime? expiresAt,
}) {
  return DiseaseAlertModel(
    id: id,
    title: 'Alert $id',
    description: 'desc',
    disease: 'PPR',
    affectedSpecies: 'sheep',
    severity: severity,
    district: district,
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    radiusKm: 50,
    sourceAuthority: 'AH Dept',
    isActive: isActive,
    issuedAt: issuedAt ?? DateTime.now(),
    expiresAt: expiresAt,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late DiseaseAlertRepository repo;

  const originLat = 16.3067;
  const originLng = 80.4365;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = DiseaseAlertRepository(firestore: firestore);
  });

  group('watchNearby', () {
    test('returns active alerts within the radius, critical severity first', () async {
      await firestore
          .collection('disease_alerts')
          .add(_alert(id: 'medium', lat: originLat + 0.01, lng: originLng, severity: 'medium')
              .toFirestore());
      await firestore
          .collection('disease_alerts')
          .add(_alert(id: 'critical', lat: originLat + 0.01, lng: originLng, severity: 'critical')
              .toFirestore());

      final results =
          await repo.watchNearby(lat: originLat, lng: originLng, radiusKm: 50).first;

      expect(results, hasLength(2));
      expect(results.first.id, isNotEmpty);
      expect(results.map((a) => a.severity), ['critical', 'medium']);
    });

    test('excludes alerts outside the radius entirely', () async {
      await firestore
          .collection('disease_alerts')
          .add(_alert(id: 'far', lat: originLat + 5, lng: originLng).toFirestore());

      final results =
          await repo.watchNearby(lat: originLat, lng: originLng, radiusKm: 20).first;
      expect(results, isEmpty);
    });

    test('excludes inactive alerts', () async {
      await firestore
          .collection('disease_alerts')
          .add(_alert(id: 'inactive', lat: originLat, lng: originLng, isActive: false)
              .toFirestore());

      final results =
          await repo.watchNearby(lat: originLat, lng: originLng, radiusKm: 50).first;
      expect(results, isEmpty);
    });

    test('excludes expired alerts', () async {
      await firestore.collection('disease_alerts').add(_alert(
            id: 'expired',
            lat: originLat,
            lng: originLng,
            expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          ).toFirestore());

      final results =
          await repo.watchNearby(lat: originLat, lng: originLng, radiusKm: 50).first;
      expect(results, isEmpty);
    });
  });

  group('watchByDistrict', () {
    test('returns active alerts for the given district, most recent first', () async {
      await firestore.collection('disease_alerts').add(_alert(
            id: 'old',
            lat: originLat,
            lng: originLng,
            district: 'Guntur',
            issuedAt: DateTime(2025, 1, 1),
          ).toFirestore());
      await firestore.collection('disease_alerts').add(_alert(
            id: 'new',
            lat: originLat,
            lng: originLng,
            district: 'Guntur',
            issuedAt: DateTime(2026, 6, 1),
          ).toFirestore());

      final results = await repo.watchByDistrict('Guntur').first;

      expect(results, hasLength(2));
      expect(results.map((a) => a.title), ['Alert new', 'Alert old']);
    });

    test('excludes alerts from other districts', () async {
      await firestore
          .collection('disease_alerts')
          .add(_alert(id: 'x', lat: originLat, lng: originLng, district: 'Krishna')
              .toFirestore());

      final results = await repo.watchByDistrict('Guntur').first;
      expect(results, isEmpty);
    });
  });

  group('watchAlert', () {
    test('streams a single alert document by id', () async {
      final ref = await firestore
          .collection('disease_alerts')
          .add(_alert(id: 'x', lat: originLat, lng: originLng).toFirestore());
      final alert = await repo.watchAlert(ref.id).first;
      expect(alert, isNotNull);
      expect(alert!.disease, 'PPR');
    });

    test('returns null for a non-existent alert id', () async {
      final alert = await repo.watchAlert('does-not-exist').first;
      expect(alert, isNull);
    });

    test('a document missing lat/lng loads with a safe 0,0 default instead of throwing',
        () async {
      // Matches FarmModel.fromFirestore's nullable-safe cast pattern —
      // DiseaseAlertModel used to do `(d['lat'] as num).toDouble()`
      // (non-nullable), which would throw on a malformed/legacy doc
      // instead of degrading gracefully.
      final malformedDoc = _alert(id: 'malformed', lat: originLat, lng: originLng).toFirestore()
        ..remove('lat')
        ..remove('lng');
      final ref = await firestore.collection('disease_alerts').add(malformedDoc);

      final alert = await repo.watchAlert(ref.id).first;

      expect(alert, isNotNull);
      expect(alert!.lat, 0);
      expect(alert.lng, 0);
    });
  });

  group('createAlert / deactivateAlert', () {
    test('createAlert adds a new document and returns its id', () async {
      final id =
          await repo.createAlert(_alert(id: '', lat: originLat, lng: originLng));
      expect(id, isNotEmpty);

      final doc = await firestore.collection('disease_alerts').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['disease'], 'PPR');
    });

    test('deactivateAlert sets isActive to false without touching other fields', () async {
      final ref = await firestore
          .collection('disease_alerts')
          .add(_alert(id: 'x', lat: originLat, lng: originLng).toFirestore());

      await repo.deactivateAlert(ref.id);

      final doc = await firestore.collection('disease_alerts').doc(ref.id).get();
      expect(doc.data()!['isActive'], isFalse);
      expect(doc.data()!['disease'], 'PPR');
    });
  });
}
