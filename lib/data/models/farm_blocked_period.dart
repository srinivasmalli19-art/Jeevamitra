import 'package:cloud_firestore/cloud_firestore.dart';

class FarmBlockedPeriod {
  final String id;
  final String farmId;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final DateTime createdAt;

  const FarmBlockedPeriod({
    required this.id,
    required this.farmId,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.createdAt,
  });

  factory FarmBlockedPeriod.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return FarmBlockedPeriod(
      id: doc.id,
      farmId: d['farmId'] as String? ?? '',
      startDate: (d['startDate'] as Timestamp).toDate(),
      endDate: (d['endDate'] as Timestamp).toDate(),
      reason: d['reason'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'farmId': farmId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        if (reason != null) 'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool containsDate(DateTime day) {
    final d = _norm(day);
    return !d.isBefore(_norm(startDate)) && !d.isAfter(_norm(endDate));
  }

  bool overlaps(DateTime start, DateTime end) =>
      startDate.isBefore(end) && endDate.isAfter(start);

  int get lengthInDays =>
      endDate.difference(startDate).inDays + 1;

  static DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);
}
