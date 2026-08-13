import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/vet_model.dart';
import '../../../data/repositories/vet_repository.dart';
import '../auth/auth_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final vetRepositoryProvider = Provider<VetRepository>((_) => VetRepository());

// ── Nearby vets ───────────────────────────────────────────────────────────────

// autoDispose: without it, every distinct (lat, lng, radiusKm) a shepherd
// selects (up to 4 radius chips per session) leaves its Firestore listener
// running for the app's lifetime — the same unbounded-listener leak fixed
// on nearbyFarmsProvider in Batch 2B.
//
// Auth-gated the same way nearbyFarmsProvider already was: previously this
// provider queried Firestore regardless of auth state, relying entirely on
// the router's redirect guard to keep it from ever being watched while
// signed out — real protection in normal navigation, but one inconsistent
// step short of nearbyFarmsProvider's defense-in-depth. Watching this
// unauthenticated fires a query Firestore rules would reject anyway,
// surfacing as a RetryCard error instead of an empty state.
final nearbyVetsProvider = StreamProvider.autoDispose
    .family<List<VetModel>, ({double lat, double lng, double radiusKm})>(
        (ref, params) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(vetRepositoryProvider).watchNearby(
        lat: params.lat,
        lng: params.lng,
        radiusKm: params.radiusKm,
      );
});

// ── Single vet ────────────────────────────────────────────────────────────────

// autoDispose: a shepherd browsing several vet profiles in one session
// (Nearby Lands -> Vets Nearby -> back and forth) previously left every
// visited vetId's listener running for the app's lifetime — the same
// unbounded-listener leak already fixed on the .family list providers.
// Safe here specifically because vetDetailProvider has no consumer outside
// the Explore ecosystem (unlike farmDetailProvider, which Bookings'
// book_land_screen.dart also depends on and is therefore left untouched
// this batch).
final vetDetailProvider =
    StreamProvider.autoDispose.family<VetModel?, String>((ref, vetId) {
  return ref.watch(vetRepositoryProvider).watchVet(vetId);
});
