import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/farm_blocked_period.dart';
import '../../../data/repositories/farm_availability_repository.dart';

final farmAvailabilityRepositoryProvider =
    Provider<FarmAvailabilityRepository>((_) => FarmAvailabilityRepository());

final farmBlockedPeriodsProvider =
    StreamProvider.family<List<FarmBlockedPeriod>, String>((ref, farmId) {
  if (farmId.isEmpty) return Stream.value([]);
  return ref
      .watch(farmAvailabilityRepositoryProvider)
      .watchBlockedPeriods(farmId);
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class FarmAvailabilityNotifier extends StateNotifier<AsyncValue<void>> {
  FarmAvailabilityNotifier(this._repo) : super(const AsyncValue.data(null));

  final FarmAvailabilityRepository _repo;

  /// Returns null on success, or the thrown error for the caller to
  /// translate and show.
  Future<Object?> addBlockedPeriod(
      String farmId, DateTime start, DateTime end, String? reason) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addBlockedPeriod(farmId, start, end, reason);
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return e;
    }
  }

  /// Returns null on success, or the thrown error for the caller to
  /// translate and show.
  Future<Object?> removeBlockedPeriod(String farmId, String periodId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.removeBlockedPeriod(farmId, periodId);
      state = const AsyncValue.data(null);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return e;
    }
  }
}

final farmAvailabilityNotifierProvider =
    StateNotifierProvider<FarmAvailabilityNotifier, AsyncValue<void>>(
  (ref) =>
      FarmAvailabilityNotifier(ref.read(farmAvailabilityRepositoryProvider)),
);
