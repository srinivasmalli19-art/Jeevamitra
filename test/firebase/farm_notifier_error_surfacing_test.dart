// Covers the Batch 3 audit fix: AddFarmNotifier and FarmAvailabilityNotifier
// used to swallow the real exception and return a bare bool/void, which is
// how "permission denied" and "session expired" ended up as generic
// "Failed to save" snackbars (or, for availability delete, no feedback at
// all). Both notifiers now return null on success or the thrown error on
// failure, so the screen can translate and show the real reason.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/repositories/farm_availability_repository.dart';
import 'package:jeevamitra/data/repositories/farm_repository.dart';
import 'package:jeevamitra/presentation/providers/farm/farm_availability_providers.dart';
import 'package:jeevamitra/presentation/providers/farm/farm_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockFarmRepository extends Mock implements FarmRepository {}

class _MockFarmAvailabilityRepository extends Mock
    implements FarmAvailabilityRepository {}

void main() {
  group('AddFarmNotifier error surfacing', () {
    late _MockFarmRepository repo;
    late AddFarmNotifier notifier;

    setUp(() {
      repo = _MockFarmRepository();
      notifier = AddFarmNotifier(repo);
    });

    test('toggleAvailability returns null on success', () async {
      when(() => repo.toggleAvailability(any(), any())).thenAnswer((_) async {});
      final result = await notifier.toggleAvailability('farm-1', true);
      expect(result, isNull);
    });

    test('toggleAvailability returns the thrown error on failure instead of throwing', () async {
      final error = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      when(() => repo.toggleAvailability(any(), any())).thenThrow(error);

      final result = await notifier.toggleAvailability('farm-1', true);

      expect(result, same(error));
    });

    test('updateFarm returns null on success, the error on failure', () async {
      when(() => repo.updateFarm(any(), any())).thenAnswer((_) async {});
      expect(await notifier.updateFarm('farm-1', {'title': 'x'}), isNull);

      final error = FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
      when(() => repo.updateFarm(any(), any())).thenThrow(error);
      expect(await notifier.updateFarm('farm-1', {'title': 'x'}), same(error));
    });

    test('deleteFarm returns null on success, the error on failure', () async {
      when(() => repo.deleteFarm(any())).thenAnswer((_) async {});
      expect(await notifier.deleteFarm('farm-1'), isNull);

      final error = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      when(() => repo.deleteFarm(any())).thenThrow(error);
      expect(await notifier.deleteFarm('farm-1'), same(error));
    });
  });

  group('FarmAvailabilityNotifier error surfacing', () {
    late _MockFarmAvailabilityRepository repo;
    late FarmAvailabilityNotifier notifier;

    setUp(() {
      repo = _MockFarmAvailabilityRepository();
      notifier = FarmAvailabilityNotifier(repo);
    });

    test('addBlockedPeriod returns null on success, the error on failure', () async {
      when(() => repo.addBlockedPeriod(any(), any(), any(), any()))
          .thenAnswer((_) async {});
      expect(
        await notifier.addBlockedPeriod('farm-1', DateTime(2026, 1, 1), DateTime(2026, 1, 2), null),
        isNull,
      );

      final error = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      when(() => repo.addBlockedPeriod(any(), any(), any(), any())).thenThrow(error);
      expect(
        await notifier.addBlockedPeriod('farm-1', DateTime(2026, 1, 1), DateTime(2026, 1, 2), null),
        same(error),
      );
    });

    test('removeBlockedPeriod returns null on success, the error on failure '
        '(previously this failure was completely silent)', () async {
      when(() => repo.removeBlockedPeriod(any(), any())).thenAnswer((_) async {});
      expect(await notifier.removeBlockedPeriod('farm-1', 'period-1'), isNull);

      final error = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      when(() => repo.removeBlockedPeriod(any(), any())).thenThrow(error);
      expect(await notifier.removeBlockedPeriod('farm-1', 'period-1'), same(error));
    });
  });
}
