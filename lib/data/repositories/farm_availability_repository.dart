import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/farm_blocked_period.dart';

class FarmAvailabilityRepository {
  CollectionReference<FarmBlockedPeriod> _col(String farmId) =>
      FirebaseFirestore.instance
          .collection(FirebaseConstants.farms)
          .doc(farmId)
          .collection(FirebaseConstants.blockedPeriods)
          .withConverter<FarmBlockedPeriod>(
            fromFirestore: (snap, _) => FarmBlockedPeriod.fromFirestore(snap),
            toFirestore: (p, _) => p.toFirestore(),
          );

  Stream<List<FarmBlockedPeriod>> watchBlockedPeriods(String farmId) => _col(farmId)
      .orderBy('startDate')
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Future<void> addBlockedPeriod(
      String farmId, DateTime start, DateTime end, String? reason) async {
    // Normalise to midnight so date arithmetic is clean
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    await _col(farmId).add(FarmBlockedPeriod(
      id: '',
      farmId: farmId,
      startDate: s,
      endDate: e,
      reason: reason?.trim().isEmpty == true ? null : reason,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> removeBlockedPeriod(String farmId, String periodId) =>
      _col(farmId).doc(periodId).delete();

  static bool hasConflict(
      List<FarmBlockedPeriod> periods, DateTime start, DateTime end) {
    return periods.any((p) => p.overlaps(start, end));
  }
}
