import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/repositories/booking_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final bookingRepositoryProvider =
    Provider<BookingRepository>((_) => BookingRepository());

// ── Farmer's incoming bookings ────────────────────────────────────────────────

final farmerBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(bookingRepositoryProvider).watchFarmerBookings(uid);
});

// ── Shepherd's own bookings ───────────────────────────────────────────────────

final shepherdBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(bookingRepositoryProvider).watchShepherdBookings(uid);
});

// ── Single booking detail ─────────────────────────────────────────────────────

final bookingDetailProvider =
    StreamProvider.family<BookingModel?, String>((ref, id) {
  return ref.watch(bookingRepositoryProvider).watchBooking(id);
});

// ── Booking actions notifier ──────────────────────────────────────────────────

class BookingNotifier extends StateNotifier<AsyncValue<void>> {
  BookingNotifier(this._repo) : super(const AsyncValue.data(null));

  final BookingRepository _repo;

  Future<String?> createBooking(BookingModel booking) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.createBooking(booking);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> confirmBooking(String bookingId, {BookingModel? booking}) =>
      _updateStatus(bookingId, FirebaseConstants.bookingConfirmed,
          booking: booking);

  Future<bool> activateBooking(String bookingId, {BookingModel? booking}) =>
      _updateStatus(bookingId, FirebaseConstants.bookingActive,
          booking: booking);

  Future<bool> completeBooking(String bookingId, {BookingModel? booking}) =>
      _updateStatus(bookingId, FirebaseConstants.bookingCompleted,
          booking: booking);

  Future<bool> cancelBooking(String bookingId, String reason,
      {BookingModel? booking, String? cancelledByRole}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.cancelBooking(bookingId, reason,
          booking: booking, cancelledByRole: cancelledByRole);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> submitReview(
      String bookingId, double rating, String text) async {
    state = const AsyncValue.loading();
    try {
      await _repo.submitReview(bookingId, rating, text);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> _updateStatus(String id, String status,
      {BookingModel? booking}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateStatus(id, status, booking: booking);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<void>>(
  (ref) => BookingNotifier(ref.read(bookingRepositoryProvider)),
);
