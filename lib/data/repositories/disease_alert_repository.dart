import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/utils/geo_hash_helper.dart';
import '../models/disease_alert_model.dart';

class DiseaseAlertRepository {
  DiseaseAlertRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  late final _col = _firestore
      .collection(FirebaseConstants.diseaseAlerts)
      .withConverter<DiseaseAlertModel>(
        fromFirestore: (snap, _) => DiseaseAlertModel.fromFirestore(snap),
        toFirestore: (a, _) => a.toFirestore(),
      );

  /// Active alerts within radius, sorted critical-first.
  Stream<List<DiseaseAlertModel>> watchNearby({
    required double lat,
    required double lng,
    double radiusKm = 100,
  }) {
    final precision = radiusKm <= 25 ? 5 : 4;
    final (lower, upper) =
        GeoHashHelper.queryRange(lat, lng, precision: precision);

    return _col
        .where('isActive', isEqualTo: true)
        .where('geohash', isGreaterThanOrEqualTo: lower)
        .where('geohash', isLessThanOrEqualTo: upper)
        .snapshots()
        .map((snap) {
      final results = snap.docs
          .map((d) => d.data())
          .where((a) => !a.isExpired)
          .toList();

      results.sort((a, b) {
        final order = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
        final cmp = (order[a.severity] ?? 3).compareTo(order[b.severity] ?? 3);
        if (cmp != 0) return cmp;
        return b.issuedAt.compareTo(a.issuedAt);
      });
      return results;
    });
  }

  /// Single alert by id, for the Alert Detail screen.
  Stream<DiseaseAlertModel?> watchAlert(String id) =>
      _col.doc(id).snapshots().map((s) => s.data());

  /// District-level alerts for a given district name (text match).
  Stream<List<DiseaseAlertModel>> watchByDistrict(String district) => _col
      .where('isActive', isEqualTo: true)
      .where('district', isEqualTo: district)
      .orderBy('issuedAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => d.data()).where((a) => !a.isExpired).toList());

  /// All alerts reported by [uid] — active and withdrawn — newest first,
  /// for the "My Reported Alerts" screen.
  Stream<List<DiseaseAlertModel>> watchByReporter(String uid) => _col
      .where('reportedBy', isEqualTo: uid)
      .orderBy('issuedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  /// Creates the alert. Recipient discovery/notification fan-out happens
  /// server-side (Cloud Function `onDiseaseAlertCreated` in
  /// functions/index.js), not here — the client has no legitimate way to
  /// query other users' documents, and never should.
  Future<String> createAlert(DiseaseAlertModel alert) async {
    final ref = await _col.add(alert);
    return ref.id;
  }

  Future<void> deactivateAlert(String id) =>
      _col.doc(id).update({'isActive': false});
}
