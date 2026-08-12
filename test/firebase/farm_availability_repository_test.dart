import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/models/farm_blocked_period.dart';
import 'package:jeevamitra/data/repositories/farm_availability_repository.dart';

void main() {
  group('FarmAvailabilityRepository', () {
    late FakeFirebaseFirestore firestore;
    late FarmAvailabilityRepository repo;
    const farmId = 'farm-1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = FarmAvailabilityRepository(firestore: firestore);
    });

    test('addBlockedPeriod writes a period visible on watchBlockedPeriods', () async {
      await repo.addBlockedPeriod(
        farmId,
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 5),
        'Harvest season',
      );

      final periods = await repo.watchBlockedPeriods(farmId).first;
      expect(periods, hasLength(1));
      expect(periods.first.reason, 'Harvest season');
      expect(periods.first.startDate, DateTime(2026, 8, 1));
      expect(periods.first.endDate, DateTime(2026, 8, 5));
    });

    test('addBlockedPeriod normalizes a blank reason to null', () async {
      await repo.addBlockedPeriod(
          farmId, DateTime(2026, 8, 1), DateTime(2026, 8, 2), '   ');

      final periods = await repo.watchBlockedPeriods(farmId).first;
      expect(periods.first.reason, isNull);
    });

    test('periods for one farm are not visible under another farm\'s subcollection', () async {
      await repo.addBlockedPeriod(
          farmId, DateTime(2026, 8, 1), DateTime(2026, 8, 2), null);

      final otherFarmPeriods = await repo.watchBlockedPeriods('farm-2').first;
      expect(otherFarmPeriods, isEmpty);
    });

    test('removeBlockedPeriod deletes it from the subcollection', () async {
      await repo.addBlockedPeriod(
          farmId, DateTime(2026, 8, 1), DateTime(2026, 8, 2), null);
      final period = (await repo.watchBlockedPeriods(farmId).first).first;

      await repo.removeBlockedPeriod(farmId, period.id);

      final periods = await repo.watchBlockedPeriods(farmId).first;
      expect(periods, isEmpty);
    });

    test('watchBlockedPeriods orders by startDate ascending', () async {
      await repo.addBlockedPeriod(
          farmId, DateTime(2026, 9, 1), DateTime(2026, 9, 2), 'later');
      await repo.addBlockedPeriod(
          farmId, DateTime(2026, 8, 1), DateTime(2026, 8, 2), 'earlier');

      final periods = await repo.watchBlockedPeriods(farmId).first;
      expect(periods.map((p) => p.reason), ['earlier', 'later']);
    });

    group('hasConflict', () {
      final existing = [
        FarmBlockedPeriod(
          id: 'x',
          farmId: farmId,
          startDate: DateTime(2026, 8, 10),
          endDate: DateTime(2026, 8, 15),
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      test('true for an overlapping range', () {
        expect(
          FarmAvailabilityRepository.hasConflict(
              existing, DateTime(2026, 8, 12), DateTime(2026, 8, 20)),
          isTrue,
        );
      });

      test('false for a non-overlapping range', () {
        expect(
          FarmAvailabilityRepository.hasConflict(
              existing, DateTime(2026, 9, 1), DateTime(2026, 9, 5)),
          isFalse,
        );
      });
    });
  });
}
