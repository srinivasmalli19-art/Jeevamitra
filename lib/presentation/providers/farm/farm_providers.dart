import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/farm_model.dart';
import '../../../data/repositories/farm_repository.dart';

// ─── Repository singleton ─────────────────────────────────────────────────────

final farmRepositoryProvider = Provider<FarmRepository>((_) => FarmRepository());

// ─── My farms (current user) ──────────────────────────────────────────────────

final myFarmsProvider = StreamProvider<List<FarmModel>>((ref) {
  final repo = ref.watch(farmRepositoryProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return repo.watchMyFarms(uid);
});

// ─── Single farm detail ───────────────────────────────────────────────────────

final farmDetailProvider =
    StreamProvider.family<FarmModel?, String>((ref, farmId) {
  final repo = ref.watch(farmRepositoryProvider);
  return repo.watchFarm(farmId);
});

// ─── Nearby farms (shepherd discovery) ───────────────────────────────────────

final nearbyFarmsProvider =
    StreamProvider.family<List<FarmModel>, ({double lat, double lng, double radiusKm})>(
        (ref, params) {
  final repo = ref.watch(farmRepositoryProvider);
  return repo.watchNearby(
    lat: params.lat,
    lng: params.lng,
    radiusKm: params.radiusKm,
  );
});

// ─── Add / Edit farm notifier ─────────────────────────────────────────────────

class AddFarmNotifier extends StateNotifier<AsyncValue<void>> {
  AddFarmNotifier(this._repo) : super(const AsyncValue.data(null));

  final FarmRepository _repo;

  Future<String?> addFarm(FarmModel farm) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.addFarm(farm);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateFarm(String farmId, Map<String, dynamic> fields) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateFarm(farmId, fields);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteFarm(String farmId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteFarm(farmId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> toggleAvailability(String farmId, bool isAvailable) async {
    await _repo.toggleAvailability(farmId, isAvailable);
  }
}

final addFarmProvider =
    StateNotifierProvider<AddFarmNotifier, AsyncValue<void>>(
  (ref) => AddFarmNotifier(ref.read(farmRepositoryProvider)),
);
