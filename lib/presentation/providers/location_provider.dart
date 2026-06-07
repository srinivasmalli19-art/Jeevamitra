import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/location_service.dart';

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LocationNotifier extends StateNotifier<AsyncValue<LocationResult?>> {
  LocationNotifier() : super(const AsyncValue.data(null));

  final _service = LocationService();

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.getCurrentLocation();
      state = AsyncValue.data(result);
    } catch (e, st) {
      // Try last known as fallback
      try {
        final last = await _service.getLastKnown();
        state = AsyncValue.data(last);
      } catch (_) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void clear() => state = const AsyncValue.data(null);
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<LocationResult?>>(
  (_) => LocationNotifier(),
);
