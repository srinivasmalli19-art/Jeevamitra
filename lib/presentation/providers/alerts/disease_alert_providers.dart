import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/disease_alert_model.dart';
import '../../../data/repositories/disease_alert_repository.dart';

final diseaseAlertRepositoryProvider =
    Provider<DiseaseAlertRepository>((_) => DiseaseAlertRepository());

final nearbyAlertsProvider = StreamProvider.family<List<DiseaseAlertModel>,
    ({double lat, double lng, double radiusKm})>((ref, params) {
  return ref.watch(diseaseAlertRepositoryProvider).watchNearby(
        lat: params.lat,
        lng: params.lng,
        radiusKm: params.radiusKm,
      );
});

final districtAlertsProvider =
    StreamProvider.family<List<DiseaseAlertModel>, String>((ref, district) {
  return ref.watch(diseaseAlertRepositoryProvider).watchByDistrict(district);
});

// ── Create / manage alerts ────────────────────────────────────────────────────

class DiseaseAlertNotifier extends StateNotifier<AsyncValue<void>> {
  DiseaseAlertNotifier(this._repo) : super(const AsyncValue.data(null));

  final DiseaseAlertRepository _repo;

  Future<bool> createAlert(DiseaseAlertModel alert) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createAlert(alert);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deactivateAlert(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deactivateAlert(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final diseaseAlertNotifierProvider =
    StateNotifierProvider<DiseaseAlertNotifier, AsyncValue<void>>(
  (ref) => DiseaseAlertNotifier(ref.read(diseaseAlertRepositoryProvider)),
);
