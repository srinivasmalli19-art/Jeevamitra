import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/booking_model.dart';

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

  Future<String> createBooking(BookingModel booking) async {
    final batch = _firestore.batch();
    final bookingRef = _col.doc();
    batch.set(bookingRef, booking);
    // Notify farmer of new booking request
    _addNotifToBatch(
      batch,
      userId: booking.farmerId,
      type: 'booking_request',
      title: 'New booking request',
      body: '${booking.shepherdName} wants to book ${booking.farmTitle} for ${booking.animalCount} animals.',
      payload: {'bookingId': bookingRef.id, 'role': 'farmer'},
    );
    await batch.commit();
    return bookingRef.id;
  }

  Future<void> updateStatus(String bookingId, String status,
      {BookingModel? booking}) async {
    final update = <String, dynamic>{'status': status};
    if (status == FirebaseConstants.bookingConfirmed) {
      update['confirmedAt'] = FieldValue.serverTimestamp();
    }

    if (booking == null) {
      await _col.doc(bookingId).update(update);
      return;
    }

    final batch = _firestore.batch();
    batch.update(_col.doc(bookingId), update);
    _applyStatusNotif(batch, status, bookingId, booking);
    await batch.commit();
  }

  Future<void> cancelBooking(String bookingId, String reason,
      {BookingModel? booking}) async {
    final batch = _firestore.batch();
    batch.update(_col.doc(bookingId), {
      'status': FirebaseConstants.bookingCancelled,
      'cancellationReason': reason,
    });
    if (booking != null) {
      _applyStatusNotif(batch, FirebaseConstants.bookingCancelled, bookingId,
          booking, cancelReason: reason);
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
  }) {
    switch (status) {
      case 'confirmed':
        _addNotifToBatch(
          batch,
          userId: booking.shepherdId,
          type: 'booking_confirmed',
          title: 'Booking confirmed!',
          body: 'Your booking at ${booking.farmTitle} has been confirmed by the farmer.',
          payload: {'bookingId': bookingId, 'role': 'shepherd'},
        );
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
        // Notify the party that didn't cancel (unknown here, notify shepherd)
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
