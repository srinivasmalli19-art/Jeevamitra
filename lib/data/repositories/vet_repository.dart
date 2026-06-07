import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/utils/geo_hash_helper.dart';
import '../models/vet_model.dart';

class VetRepository {
  final _col = FirebaseFirestore.instance
      .collection(FirebaseConstants.vets)
      .withConverter<VetModel>(
        fromFirestore: (snap, _) => VetModel.fromFirestore(snap),
        toFirestore: (v, _) => v.toFirestore(),
      );

  // ── Nearby vets via geohash range ────────────────────────────────────────

  Stream<List<VetModel>> watchNearby({
    required double lat,
    required double lng,
    double radiusKm = 50,
  }) {
    final precision = _precisionFor(radiusKm);
    final (lower, upper) = GeoHashHelper.queryRange(lat, lng, precision: precision);

    return _col
        .where('geohash', isGreaterThanOrEqualTo: lower)
        .where('geohash', isLessThanOrEqualTo: upper)
        .snapshots()
        .map((snap) {
      final results = snap.docs
          .map((d) => d.data())
          .where((v) =>
              GeoHashHelper.distanceKm(lat, lng, v.lat, v.lng) <= radiusKm)
          .toList();
      results.sort((a, b) {
        final da = GeoHashHelper.distanceKm(lat, lng, a.lat, a.lng);
        final db = GeoHashHelper.distanceKm(lat, lng, b.lat, b.lng);
        return da.compareTo(db);
      });
      return results;
    });
  }

  // ── Single vet ────────────────────────────────────────────────────────────

  Stream<VetModel?> watchVet(String vetId) =>
      _col.doc(vetId).snapshots().map((s) => s.data());

  // ── Precision selection ───────────────────────────────────────────────────

  int _precisionFor(double radiusKm) {
    if (radiusKm <= 10) return 6;
    if (radiusKm <= 25) return 5;
    if (radiusKm <= 100) return 4;
    return 3;
  }
}
