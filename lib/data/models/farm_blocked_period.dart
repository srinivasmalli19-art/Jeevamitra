import 'package:cloud_firestore/cloud_firestore.dart';

class FarmBlockedPeriod {
  final String id;
  final String farmId;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final DateTime createdAt;

  /// Set only for periods BookingRepository auto-creates when a booking is
  /// confirmed (see createBooking/updateStatus) — null for periods the
  /// farmer added manually via FarmAvailabilityRepository. Lets a confirmed
  /// booking's reservation be found and released again on cancellation
  /// without disturbing manual blocks.
  final String? bookingId;

  const FarmBlockedPeriod({
    required this.id,
    required this.farmId,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.createdAt,
    this.bookingId,
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
      bookingId: d['bookingId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'farmId': farmId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        if (reason != null) 'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
        if (bookingId != null) 'bookingId': bookingId,
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
