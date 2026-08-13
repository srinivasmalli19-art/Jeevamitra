import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/disease_alert_model.dart';
import '../../../data/repositories/disease_alert_repository.dart';
import '../auth/auth_provider.dart';

final diseaseAlertRepositoryProvider =
    Provider<DiseaseAlertRepository>((_) => DiseaseAlertRepository());

// Auth-gated the same way nearbyFarmsProvider already was (see that
// provider's comment): previously this queried Firestore regardless of
// auth state, relying entirely on the router's redirect guard. Watching
// unauthenticated fires a query Firestore rules would reject anyway,
// surfacing as a RetryCard error instead of an empty state — both the
// Farmer Explore tab and the shepherd-facing alert map/search reach this
// provider, and both routes are already auth-guarded, so this is
// defense-in-depth, not a behavior change for any real navigation path.
final nearbyAlertsProvider = StreamProvider.autoDispose.family<
    List<DiseaseAlertModel>,
    ({double lat, double lng, double radiusKm})>((ref, params) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(diseaseAlertRepositoryProvider).watchNearby(
        lat: params.lat,
        lng: params.lng,
        radiusKm: params.radiusKm,
      );
});

final districtAlertsProvider = StreamProvider.autoDispose
    .family<List<DiseaseAlertModel>, String>((ref, district) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(diseaseAlertRepositoryProvider).watchByDistrict(district);
});

final alertDetailProvider =
    StreamProvider.autoDispose.family<DiseaseAlertModel?, String>((ref, alertId) {
  return ref.watch(diseaseAlertRepositoryProvider).watchAlert(alertId);
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
