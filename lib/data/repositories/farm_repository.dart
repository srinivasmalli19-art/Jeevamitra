import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/services/image_upload_service.dart';
import '../../core/utils/geo_hash_helper.dart';
import '../models/farm_model.dart';

class FarmRepository {
  FarmRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ImageUploadService? imageUploadService,
  })  : _firestoreOverride = firestore,
        _authOverride = auth,
        _imageUploadOverride = imageUploadService;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;
  final ImageUploadService? _imageUploadOverride;

  // Resolved lazily (not in the initializer list) so constructing this class
  // with only one override supplied doesn't force-touch the other real
  // Firebase singleton before it's actually needed.
  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  ImageUploadService get _imageUpload => _imageUploadOverride ?? ImageUploadService();

  late final _col = _firestore.collection(FirebaseConstants.farms);

  /// Reserves a Firestore document ID without writing anything — lets
  /// callers (the Add/Edit Land photo step) know the farmId up front so
  /// photos can be uploaded to `farms/{ownerId}/{farmId}/...` before the
  /// farm document itself exists.
  String reserveFarmId() => _col.doc().id;

  // ── Streams ──────────────────────────────────────────────────────────────

  /// All farms owned by the current user — live stream.
  Stream<List<FarmModel>> watchMyFarms(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  /// Farms within ~radiusKm of [lat,lng] — uses geohash range query.
  Stream<List<FarmModel>> watchNearby({
    required double lat,
    required double lng,
    double radiusKm = 50,
    bool onlyAvailable = true,
  }) {
    final precision = _precisionFor(radiusKm);
    final (lower, upper) = GeoHashHelper.queryRange(lat, lng, precision: precision);

    var query = _col
        .where('geohash', isGreaterThanOrEqualTo: lower)
        .where('geohash', isLessThanOrEqualTo: upper);

    if (onlyAvailable) query = query.where('isAvailable', isEqualTo: true);

    return query.snapshots().map((snap) {
      final results = snap.docs.map(_fromDoc).toList();
      // Client-side filter: Haversine removes cells outside actual circle
      results.removeWhere((f) =>
          GeoHashHelper.distanceKm(lat, lng, f.lat, f.lng) > radiusKm);
      results.sort((a, b) =>
          GeoHashHelper.distanceKm(lat, lng, a.lat, a.lng)
              .compareTo(GeoHashHelper.distanceKm(lat, lng, b.lat, b.lng)));
      return results;
    });
  }

  /// Single farm document — live stream.
  Stream<FarmModel?> watchFarm(String farmId) {
    return _col.doc(farmId).snapshots().map(
          (doc) => doc.exists ? _fromDoc(doc) : null,
        );
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  Future<String> addFarm(FarmModel farm) async {
    // Honor a pre-reserved id (see reserveFarmId()) so photos already
    // uploaded to farms/{ownerId}/{farmId}/... under that id land on the
    // same document instead of an orphaned mismatched one.
    final ref = farm.id.isNotEmpty ? _col.doc(farm.id) : _col.doc();
    final model = farm.copyWithModel(); // ensure geohash is set
    final data = model.toFirestore();
    // watchMyFarms() orderBy('createdAt') must sort by the server's clock,
    // not the caller's device clock, so a skewed device doesn't push a new
    // listing out of order (or off the top) in My Lands.
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  Future<void> updateFarm(String farmId, Map<String, dynamic> fields) async {
    // Recalculate geohash if location changed
    if (fields.containsKey('lat') && fields.containsKey('lng')) {
      fields['geohash'] = GeoHashHelper.encode(
        (fields['lat'] as num).toDouble(),
        (fields['lng'] as num).toDouble(),
      );
    }
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(farmId).update(fields);
  }

  /// Deletes the farm document, then sweeps its Storage photo folder so no
  /// orphaned images are left behind. Storage cleanup runs after the
  /// Firestore delete (not before) so a mid-operation failure never leaves
  /// a farm doc pointing at photos that no longer exist — the reverse
  /// order could.
  Future<void> deleteFarm(String farmId) async {
    final snap = await _col.doc(farmId).get();
    final ownerId = snap.data()?['ownerId'] as String?;
    await _col.doc(farmId).delete();
    if (ownerId != null && ownerId.isNotEmpty) {
      await _imageUpload.deleteFarmFolder(ownerId: ownerId, farmId: farmId);
    }
  }

  Future<void> toggleAvailability(String farmId, bool isAvailable) async {
    await _col.doc(farmId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Auth guard ────────────────────────────────────────────────────────────

  String get currentUid => _auth.currentUser?.uid ?? '';

  bool ownsDoc(FarmModel farm) => farm.ownerId == currentUid;

  // ── Helpers ───────────────────────────────────────────────────────────────

  FarmModel _fromDoc(DocumentSnapshot doc) =>
      FarmModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);

  /// Lower precision = larger bounding box for bigger radii
  int _precisionFor(double radiusKm) {
    if (radiusKm <= 5) return 6;
    if (radiusKm <= 20) return 5;
    if (radiusKm <= 100) return 4;
    return 3;
  }
}
