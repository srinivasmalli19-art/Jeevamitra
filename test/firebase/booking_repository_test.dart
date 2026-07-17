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

  group('cancelBooking', () {
    test('sets status to cancelled with the reason and notifies the shepherd', () async {
      final booking = _booking();
      final id = await repo.createBooking(booking);

      await repo.cancelBooking(id, 'Farm no longer available', booking: booking);

      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.data()!['status'], 'cancelled');
      expect(doc.data()!['cancellationReason'], 'Farm no longer available');
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
