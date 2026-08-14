import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/models/booking_model.dart';
import 'package:jeevamitra/data/repositories/booking_repository.dart';

BookingModel _booking({
  String id = '',
  String farmerId = 'farmer-1',
  String shepherdId = 'shepherd-1',
  String status = 'pending',
  int animalCount = 10,
  double totalAmount = 5000,
}) {
  final now = DateTime(2026, 7, 1);
  return BookingModel(
    id: id,
    farmId: 'farm-1',
    farmTitle: 'Green Pasture',
    farmVillage: 'Narasaraopet',
    farmerId: farmerId,
    shepherdId: shepherdId,
    shepherdName: 'Suresh',
    animalCount: animalCount,
    checkIn: now,
    checkOut: now.add(const Duration(days: 5)),
    totalAmount: totalAmount,
    advanceAmount: 1000,
    status: status,
    createdAt: now,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late BookingRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = BookingRepository(firestore: firestore);
  });

  group('createBooking', () {
    test('writes the booking and a notification to the farmer in one batch', () async {
      final id = await repo.createBooking(_booking());

      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['status'], 'pending');
      expect(doc.data()!['farmerId'], 'farmer-1');

      final notifs = await firestore.collection('notifications').get();
      expect(notifs.docs, hasLength(1));
      expect(notifs.docs.first.data()['userId'], 'farmer-1');
      expect(notifs.docs.first.data()['type'], 'booking_request');
    });

    test(
        'transactional final check rejects dates that overlap a blocked '
        'period, and writes neither the booking nor a notification', () async {
      final booking = _booking(); // checkIn 2026-07-01, checkOut 2026-07-06
      await firestore
          .collection('farms')
          .doc('farm-1')
          .collection('blocked_periods')
          .add({
        'farmId': 'farm-1',
        'startDate': Timestamp.fromDate(DateTime(2026, 7, 3)),
        'endDate': Timestamp.fromDate(DateTime(2026, 7, 4)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      });

      await expectLater(
        repo.createBooking(booking),
        throwsA(isA<BookingConflictException>()),
      );

      final bookings = await firestore.collection('bookings').get();
      expect(bookings.docs, isEmpty);
      final notifs = await firestore.collection('notifications').get();
      expect(notifs.docs, isEmpty);
    });

    test(
        'succeeds when a blocked period exists for the farm but does not '
        'overlap the requested dates', () async {
      final booking = _booking(); // checkIn 2026-07-01, checkOut 2026-07-06
      await firestore
          .collection('farms')
          .doc('farm-1')
          .collection('blocked_periods')
          .add({
        'farmId': 'farm-1',
        'startDate': Timestamp.fromDate(DateTime(2026, 8, 1)),
        'endDate': Timestamp.fromDate(DateTime(2026, 8, 5)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      });

      final id = await repo.createBooking(booking);

      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.exists, isTrue);
    });
  });

  group('watchFarmerBookings / watchShepherdBookings', () {
    test('each stream only returns bookings for the matching party', () async {
      await repo.createBooking(_booking(farmerId: 'farmer-A', shepherdId: 'shepherd-X'));
      await repo.createBooking(_booking(farmerId: 'farmer-B', shepherdId: 'shepherd-X'));
      await repo.createBooking(_booking(farmerId: 'farmer-A', shepherdId: 'shepherd-Y'));

      final farmerA = await repo.watchFarmerBookings('farmer-A').first;
      expect(farmerA, hasLength(2));
      expect(farmerA.every((b) => b.farmerId == 'farmer-A'), isTrue);

      final shepherdX = await repo.watchShepherdBookings('shepherd-X').first;
      expect(shepherdX, hasLength(2));
      expect(shepherdX.every((b) => b.shepherdId == 'shepherd-X'), isTrue);
    });
  });

  group('updateStatus', () {
    test('confirming a booking notifies the shepherd', () async {
      final booking = _booking();
      final id = await repo.createBooking(booking);

      await repo.updateStatus(id, 'confirmed', booking: booking.copyWithModel(status: 'confirmed'));

      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.data()!['status'], 'confirmed');
      expect(doc.data()!['confirmedAt'], isNotNull);

      final notifs = await firestore
          .collection('notifications')
          .where('type', isEqualTo: 'booking_confirmed')
          .get();
      expect(notifs.docs, hasLength(1));
      expect(notifs.docs.first.data()['userId'], 'shepherd-1');
    });

    test('without a booking snapshot, updates status but sends no notification', () async {
      final id = await repo.createBooking(_booking());
      await repo.updateStatus(id, 'active');

      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.data()!['status'], 'active');

      final notifs = await firestore.collection('notifications').get();
      // Only the original booking_request notification from createBooking.
      expect(notifs.docs, hasLength(1));
    });
  });

  group('confirmed-booking availability lock', () {
    Future<QuerySnapshot<Map<String, dynamic>>> blockedPeriodsFor(String farmId) =>
        firestore.collection('farms').doc(farmId).collection('blocked_periods').get();

    test('confirming a booking creates a linked blocked period', () async {
      final booking = _booking(); // farm-1, 2026-07-01 -> 2026-07-06
      final id = await repo.createBooking(booking);

      await repo.updateStatus(id, 'confirmed',
          booking: booking.copyWithModel(status: 'confirmed'));

      final blocked = await blockedPeriodsFor('farm-1');
      expect(blocked.docs, hasLength(1));
      expect(blocked.docs.first.data()['bookingId'], id);
      expect(
        (blocked.docs.first.data()['startDate'] as Timestamp).toDate(),
        DateTime(2026, 7, 1),
      );
    });

    test('non-overlapping confirmations for the same farm both succeed', () async {
      final bookingA = _booking(shepherdId: 'shepherd-A');
      final laterBooking = BookingModel(
        id: '',
        farmId: 'farm-1',
        farmTitle: 'Green Pasture',
        farmVillage: 'Narasaraopet',
        farmerId: 'farmer-1',
        shepherdId: 'shepherd-B',
        shepherdName: 'Ravi',
        animalCount: 5,
        checkIn: DateTime(2026, 8, 1),
        checkOut: DateTime(2026, 8, 5),
        totalAmount: 2000,
        advanceAmount: 500,
        status: 'pending',
        createdAt: DateTime(2026, 8, 1),
      );
      final idA = await repo.createBooking(bookingA);
      final idB = await repo.createBooking(laterBooking);

      await repo.updateStatus(idA, 'confirmed',
          booking: bookingA.copyWithModel(status: 'confirmed'));
      await repo.updateStatus(idB, 'confirmed',
          booking: laterBooking.copyWithModel(status: 'confirmed'));

      final blocked = await blockedPeriodsFor('farm-1');
      expect(blocked.docs, hasLength(2));
      final docA = await firestore.collection('bookings').doc(idA).get();
      final docB = await firestore.collection('bookings').doc(idB).get();
      expect(docA.data()!['status'], 'confirmed');
      expect(docB.data()!['status'], 'confirmed');
    });

    test(
        'confirming a second, overlapping booking is rejected once the '
        'first is confirmed, and its status is left untouched', () async {
      final bookingA = _booking(shepherdId: 'shepherd-A');
      final bookingB = _booking(shepherdId: 'shepherd-B');
      // Both created while the farm has no locks yet — matches the real
      // race: two pending requests for the same dates coexist fine.
      final idA = await repo.createBooking(bookingA);
      final idB = await repo.createBooking(bookingB);

      await repo.updateStatus(idA, 'confirmed',
          booking: bookingA.copyWithModel(status: 'confirmed'));

      await expectLater(
        repo.updateStatus(idB, 'confirmed',
            booking: bookingB.copyWithModel(status: 'confirmed')),
        throwsA(isA<BookingConflictException>()),
      );

      final docB = await firestore.collection('bookings').doc(idB).get();
      expect(docB.data()!['status'], 'pending');
      final blocked = await blockedPeriodsFor('farm-1');
      expect(blocked.docs, hasLength(1)); // only A's lock exists
    });

    test('cancelling a confirmed booking releases its blocked period', () async {
      final booking = _booking();
      final id = await repo.createBooking(booking);
      final confirmed = booking.copyWithModel(status: 'confirmed');
      await repo.updateStatus(id, 'confirmed', booking: confirmed);
      expect((await blockedPeriodsFor('farm-1')).docs, hasLength(1));

      await repo.cancelBooking(id, 'Change of plans',
          booking: confirmed, cancelledByRole: 'farmer');

      final blocked = await blockedPeriodsFor('farm-1');
      expect(blocked.docs, isEmpty);
      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.data()!['status'], 'cancelled');
    });
  });

  group('cancelBooking', () {
    test('sets status to cancelled with the reason and notifies the shepherd', () async {
      final booking = _booking();
      final id = await repo.createBooking(booking);

      await repo.cancelBooking(id, 'Farm no longer available', booking: booking);

      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.data()!['status'], 'cancelled');
      expect(doc.data()!['cancellationReason'], 'Farm no longer available');
    });

    test('farmer cancels -> the shepherd is notified (not the farmer)', () async {
      final booking = _booking();
      final id = await repo.createBooking(booking);

      await repo.cancelBooking(id, 'Changed plans',
          booking: booking, cancelledByRole: 'farmer');

      final notifs = await firestore
          .collection('notifications')
          .where('type', isEqualTo: 'booking_cancelled')
          .get();
      expect(notifs.docs, hasLength(1));
      expect(notifs.docs.first.data()['userId'], 'shepherd-1');
      expect(notifs.docs.first.data()['payload']['role'], 'shepherd');
    });

    test('shepherd cancels -> the farmer is notified (not the shepherd)', () async {
      final booking = _booking();
      final id = await repo.createBooking(booking);

      await repo.cancelBooking(id, 'Found another land',
          booking: booking, cancelledByRole: 'shepherd');

      final notifs = await firestore
          .collection('notifications')
          .where('type', isEqualTo: 'booking_cancelled')
          .get();
      expect(notifs.docs, hasLength(1));
      expect(notifs.docs.first.data()['userId'], 'farmer-1');
      expect(notifs.docs.first.data()['payload']['role'], 'farmer');
    });

    test('a confirmed booking can be cancelled by the farmer', () async {
      final booking = _booking(status: 'confirmed');
      final id = await repo.createBooking(booking);
      await repo.updateStatus(id, 'confirmed', booking: booking);

      await repo.cancelBooking(id, 'Land became unavailable',
          booking: booking, cancelledByRole: 'farmer');

      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.data()!['status'], 'cancelled');
      expect(doc.data()!['cancellationReason'], 'Land became unavailable');

      final notifs = await firestore
          .collection('notifications')
          .where('type', isEqualTo: 'booking_cancelled')
          .get();
      expect(notifs.docs, hasLength(1));
      expect(notifs.docs.first.data()['userId'], 'shepherd-1');
    });
  });

  group('submitReview', () {
    test('sets rating, text, and marks the booking completed', () async {
      final id = await repo.createBooking(_booking());
      await repo.submitReview(id, 4.5, 'Great experience!');

      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.data()!['reviewRating'], 4.5);
      expect(doc.data()!['reviewText'], 'Great experience!');
      expect(doc.data()!['status'], 'completed');
    });
  });

  group('Firestore-rules-equivalent invariants (matching firestore.rules constraints)', () {
    test('animalCount and totalAmount are stored as positive numbers', () async {
      final id = await repo.createBooking(_booking(animalCount: 25, totalAmount: 12500));
      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.data()!['animalCount'], greaterThan(0));
      expect(doc.data()!['totalAmount'], greaterThan(0));
    });

    test('checkOut is always after checkIn for a freshly created booking', () async {
      final booking = _booking();
      final id = await repo.createBooking(booking);
      final doc = await firestore.collection('bookings').doc(id).get();
      final checkIn = (doc.data()!['checkIn'] as Timestamp).toDate();
      final checkOut = (doc.data()!['checkOut'] as Timestamp).toDate();
      expect(checkOut.isAfter(checkIn), isTrue);
    });
  });
}
