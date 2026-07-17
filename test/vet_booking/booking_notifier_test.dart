// State-management coverage for the vet/land booking workflow: verifies
// BookingNotifier correctly reflects loading/data/error AsyncValue states
// around each repository call, independent of Firestore itself (the
// repository is mocked here; Firestore-level behavior is covered by
// test/firebase/booking_repository_test.dart).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/models/booking_model.dart';
import 'package:jeevamitra/data/repositories/booking_repository.dart';
import 'package:jeevamitra/presentation/providers/booking/booking_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

class FakeBookingModel extends Fake implements BookingModel {}

BookingModel _booking() {
  final now = DateTime(2026, 7, 1);
  return BookingModel(
    id: 'b1',
    farmId: 'farm-1',
    farmTitle: 'Green Pasture',
    farmVillage: 'Narasaraopet',
    farmerId: 'farmer-1',
    shepherdId: 'shepherd-1',
    shepherdName: 'Suresh',
    animalCount: 10,
    checkIn: now,
    checkOut: now.add(const Duration(days: 5)),
    totalAmount: 5000,
    advanceAmount: 1000,
    status: 'pending',
    createdAt: now,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBookingModel());
  });

  late MockBookingRepository mockRepo;
  late BookingNotifier notifier;

  setUp(() {
    mockRepo = MockBookingRepository();
    notifier = BookingNotifier(mockRepo);
  });

  group('createBooking', () {
    test('returns the new id and ends in data state on success', () async {
      when(() => mockRepo.createBooking(any())).thenAnswer((_) async => 'new-booking-id');

      final id = await notifier.createBooking(_booking());

      expect(id, 'new-booking-id');
      expect(notifier.state, const AsyncValue<void>.data(null));
    });

    test('returns null and captures the error on failure', () async {
      when(() => mockRepo.createBooking(any())).thenThrow(Exception('network down'));

      final id = await notifier.createBooking(_booking());

      expect(id, isNull);
      expect(notifier.state.hasError, isTrue);
    });
  });

  group('confirmBooking / activateBooking / completeBooking', () {
    test('confirmBooking calls updateStatus with "confirmed" and succeeds', () async {
      when(() => mockRepo.updateStatus(any(), 'confirmed', booking: any(named: 'booking')))
          .thenAnswer((_) async {});

      final ok = await notifier.confirmBooking('b1', booking: _booking());

      expect(ok, isTrue);
      verify(() => mockRepo.updateStatus('b1', 'confirmed', booking: any(named: 'booking')))
          .called(1);
    });

    test('activateBooking calls updateStatus with "active"', () async {
      when(() => mockRepo.updateStatus(any(), 'active', booking: any(named: 'booking')))
          .thenAnswer((_) async {});
      final ok = await notifier.activateBooking('b1');
      expect(ok, isTrue);
      verify(() => mockRepo.updateStatus('b1', 'active', booking: any(named: 'booking'))).called(1);
    });

    test('completeBooking failing surfaces as an error state and returns false', () async {
      when(() => mockRepo.updateStatus(any(), 'completed', booking: any(named: 'booking')))
          .thenThrow(Exception('permission-denied'));

      final ok = await notifier.completeBooking('b1');

      expect(ok, isFalse);
      expect(notifier.state.hasError, isTrue);
    });
  });

  group('cancelBooking', () {
    test('passes the cancellation reason through to the repository', () async {
      when(() => mockRepo.cancelBooking('b1', 'Change of plans', booking: any(named: 'booking')))
          .thenAnswer((_) async {});

      final ok = await notifier.cancelBooking('b1', 'Change of plans', booking: _booking());

      expect(ok, isTrue);
      verify(() => mockRepo.cancelBooking('b1', 'Change of plans', booking: any(named: 'booking')))
          .called(1);
    });
  });

  group('submitReview', () {
    test('rating and text reach the repository and the call succeeds', () async {
      when(() => mockRepo.submitReview('b1', 4.5, 'Great!')).thenAnswer((_) async {});
      final ok = await notifier.submitReview('b1', 4.5, 'Great!');
      expect(ok, isTrue);
    });
  });
}
