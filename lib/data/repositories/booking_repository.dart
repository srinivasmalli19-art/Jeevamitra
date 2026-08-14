import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/booking_model.dart';
import '../models/farm_blocked_period.dart';

/// Thrown by [BookingRepository.createBooking] when the transactional
/// final conflict-check finds the requested dates now overlap a blocked
/// period that didn't exist (or looked different) at the time the booking
/// form's own client-side check ran.
class BookingConflictException implements Exception {
  final String message;
  const BookingConflictException(this.message);
  @override
  String toString() => message;
}

class BookingRepository {
  BookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  late final _col = _firestore
      .collection(FirebaseConstants.bookings)
      .withConverter<BookingModel>(
        fromFirestore: (snap, _) => BookingModel.fromFirestore(snap),
        toFirestore: (b, _) => b.toFirestore(),
      );

  late final _notifications =
      _firestore.collection(FirebaseConstants.notifications);

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<BookingModel>> watchFarmerBookings(String farmerId) => _col
      .where('farmerId', isEqualTo: farmerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Stream<List<BookingModel>> watchShepherdBookings(String shepherdId) => _col
      .where('shepherdId', isEqualTo: shepherdId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Stream<BookingModel?> watchBooking(String bookingId) => _col
      .doc(bookingId)
      .snapshots()
      .map((s) => s.data());

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Creates the booking after a transactional final conflict-check against
  /// the farm's blocked periods.
  ///
  /// `BookLandScreen` already checks blocked periods client-side before the
  /// user reaches the final "submit" step, but that check can go stale —
  /// another user could add/change a blocked period in the gap between then
  /// and this write. A Firestore transaction can't re-run that check as a
  /// query (`Transaction.get()` only accepts a `DocumentReference`, not a
  /// `Query` — there is no way to ask "find any overlapping period" inside
  /// one), so the candidate periods are discovered with a plain query first,
  /// then each candidate is re-read *inside* the transaction below. That is
  /// what makes this a real transactional check rather than a cosmetic one:
  /// if any of those specific documents changes between the query and the
  /// commit, Firestore detects the conflicting read and automatically
  /// retries the whole transaction against fresh data. The one gap this
  /// can't close is a blocked period created after the initial query that
  /// was never a candidate in the first place — see BookingRepository's
  /// class-level limitations note.
  Future<String> createBooking(BookingModel booking) async {
    final bookingRef = _col.doc();

    final blockedSnap = await _firestore
        .collection(FirebaseConstants.farms)
        .doc(booking.farmId)
        .collection(FirebaseConstants.blockedPeriods)
        .get();

    await _firestore.runTransaction((transaction) async {
      for (final doc in blockedSnap.docs) {
        final fresh = await transaction.get(doc.reference);
        final data = fresh.data();
        if (data == null) continue; // removed since the discovery query
        final period = FarmBlockedPeriod.fromFirestore(fresh);
        if (period.overlaps(booking.checkIn,
            booking.checkOut.add(const Duration(days: 1)))) {
          throw const BookingConflictException(
              'These dates are no longer available. Please choose different dates.');
        }
      }

      transaction.set(bookingRef, booking);
      // Notify farmer of new booking request
      transaction.set(_notifications.doc(), {
        'userId': booking.farmerId,
        'type': 'booking_request',
        'title': 'New booking request',
        'body': '${booking.shepherdName} wants to book ${booking.farmTitle} for ${booking.animalCount} animals.',
        'payload': {'bookingId': bookingRef.id, 'role': 'farmer'},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return bookingRef.id;
  }

  Future<void> updateStatus(String bookingId, String status,
      {BookingModel? booking}) async {
    if (status == FirebaseConstants.bookingConfirmed) {
      await _confirmWithLock(bookingId, booking);
      return;
    }

    final update = <String, dynamic>{'status': status};

    if (booking == null) {
      await _col.doc(bookingId).update(update);
      return;
    }

    final batch = _firestore.batch();
    batch.update(_col.doc(bookingId), update);
    _applyStatusNotif(batch, status, bookingId, booking);
    await batch.commit();
  }

  /// Confirms the booking and, in the same transaction, reserves its dates
  /// by creating a blocked period linked to it via `bookingId` — this is
  /// what actually closes the gap Sprint 4H left open: confirming used to
  /// never affect farm availability at all, so two overlapping bookings
  /// could both be confirmed. Reuses createBooking's discovery-then-
  /// transactionally-reread pattern (a transaction can't run the discovery
  /// query itself — `Transaction.get()` only accepts a `DocumentReference`
  /// — so candidates are found first, then each is re-read via
  /// `transaction.get()` so Firestore retries the whole thing if any of
  /// them changes before commit). [booking] is fetched if not supplied,
  /// since every call site must reserve the dates on confirm regardless of
  /// whether it happened to have the booking object already in hand.
  Future<void> _confirmWithLock(String bookingId, BookingModel? booking) async {
    final effective =
        booking ?? (await _col.doc(bookingId).get()).data();
    if (effective == null) {
      // Booking vanished under us — nothing to lock against; fall back to
      // a plain status update rather than failing the confirm entirely.
      await _col.doc(bookingId).update({
        'status': FirebaseConstants.bookingConfirmed,
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final blockedCol = _firestore
        .collection(FirebaseConstants.farms)
        .doc(effective.farmId)
        .collection(FirebaseConstants.blockedPeriods);

    final blockedSnap = await blockedCol.get();

    await _firestore.runTransaction((transaction) async {
      for (final doc in blockedSnap.docs) {
        final fresh = await transaction.get(doc.reference);
        final data = fresh.data();
        if (data == null) continue; // removed since the discovery query
        final period = FarmBlockedPeriod.fromFirestore(fresh);
        if (period.overlaps(
            effective.checkIn, effective.checkOut.add(const Duration(days: 1)))) {
          throw const BookingConflictException(
              'These dates were just confirmed for another booking.');
        }
      }

      transaction.update(_col.doc(bookingId), {
        'status': FirebaseConstants.bookingConfirmed,
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(blockedCol.doc(), {
        'farmId': effective.farmId,
        'startDate': Timestamp.fromDate(effective.checkIn),
        'endDate': Timestamp.fromDate(effective.checkOut),
        'reason': 'Booking confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'bookingId': bookingId,
      });

      transaction.set(_notifications.doc(), {
        'userId': effective.shepherdId,
        'type': 'booking_confirmed',
        'title': 'Booking confirmed!',
        'body': 'Your booking at ${effective.farmTitle} has been confirmed by the farmer.',
        'payload': {'bookingId': bookingId, 'role': 'shepherd'},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// [cancelledByRole] is 'farmer' or 'shepherd' — whoever is cancelling —
  /// so the notification goes to the *other* party instead of always the
  /// shepherd. If [booking] had a confirmed-booking lock (see
  /// [_confirmWithLock]), it is released in the same batch; a booking that
  /// was never confirmed simply has no matching block, so this is a no-op
  /// for the pending-rejection path.
  Future<void> cancelBooking(String bookingId, String reason,
      {BookingModel? booking, String? cancelledByRole}) async {
    final batch = _firestore.batch();
    batch.update(_col.doc(bookingId), {
      'status': FirebaseConstants.bookingCancelled,
      'cancellationReason': reason,
    });
    if (booking != null) {
      _applyStatusNotif(batch, FirebaseConstants.bookingCancelled, bookingId,
          booking,
          cancelReason: reason, cancelledByRole: cancelledByRole);

      final linkedBlocks = await _firestore
          .collection(FirebaseConstants.farms)
          .doc(booking.farmId)
          .collection(FirebaseConstants.blockedPeriods)
          .where('bookingId', isEqualTo: bookingId)
          .get();
      for (final doc in linkedBlocks.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  Future<void> submitReview(
      String bookingId, double rating, String text) async {
    await _col.doc(bookingId).update({
      'reviewRating': rating,
      'reviewText': text,
      'status': FirebaseConstants.bookingCompleted,
    });
  }

  // ── Notification helpers ──────────────────────────────────────────────────

  void _applyStatusNotif(
    WriteBatch batch,
    String status,
    String bookingId,
    BookingModel booking, {
    String? cancelReason,
    String? cancelledByRole,
  }) {
    switch (status) {
      // 'confirmed' is handled entirely by _confirmWithLock (status update
      // + lock + notification, all in one transaction) — never reaches here.
      case 'active':
        _addNotifToBatch(
          batch,
          userId: booking.shepherdId,
          type: 'booking_active',
          title: 'Trip started',
          body: 'Your trip at ${booking.farmTitle} is now active.',
          payload: {'bookingId': bookingId, 'role': 'shepherd'},
        );
      case 'completed':
        _addNotifToBatch(
          batch,
          userId: booking.shepherdId,
          type: 'booking_completed',
          title: 'Trip completed',
          body: 'Your trip at ${booking.farmTitle} is complete. Please leave a review!',
          payload: {'bookingId': bookingId, 'role': 'shepherd'},
        );
        _addNotifToBatch(
          batch,
          userId: booking.farmerId,
          type: 'booking_completed',
          title: 'Booking completed',
          body: '${booking.shepherdName}\'s trip at ${booking.farmTitle} is complete.',
          payload: {'bookingId': bookingId, 'role': 'farmer'},
        );
      case 'cancelled':
        // Notify whichever party did NOT cancel.
        if (cancelledByRole == 'shepherd') {
          _addNotifToBatch(
            batch,
            userId: booking.farmerId,
            type: 'booking_cancelled',
            title: 'Booking cancelled',
            body: cancelReason != null
                ? '${booking.shepherdName} cancelled: $cancelReason'
                : '${booking.shepherdName} cancelled their booking at ${booking.farmTitle}.',
            payload: {'bookingId': bookingId, 'role': 'farmer'},
          );
        } else {
          _addNotifToBatch(
            batch,
            userId: booking.shepherdId,
            type: 'booking_cancelled',
            title: 'Booking cancelled',
            body: cancelReason != null
                ? 'Your booking was cancelled: $cancelReason'
                : 'Your booking at ${booking.farmTitle} was cancelled.',
            payload: {'bookingId': bookingId, 'role': 'shepherd'},
          );
        }
    }
  }

  void _addNotifToBatch(
    WriteBatch batch, {
    required String userId,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) {
    final ref = _notifications.doc();
    batch.set(ref, {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'payload': payload,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
