import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/vet_model.dart';
import '../../../data/repositories/vet_repository.dart';
import '../auth/auth_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final vetRepositoryProvider =
    Provider<VetRepository>((_) => VetRepository());

// ── Nearby vets ───────────────────────────────────────────────────────────────

final nearbyVetsProvider = StreamProvider.family<List<VetModel>,
    ({double lat, double lng, double radiusKm})>((ref, params) {
  return ref.watch(vetRepositoryProvider).watchNearby(
        lat: params.lat,
        lng: params.lng,
        radiusKm: params.radiusKm,
      );
});

// ── Single vet ────────────────────────────────────────────────────────────────

final vetDetailProvider =
    StreamProvider.family<VetModel?, String>((ref, vetId) {
  return ref.watch(vetRepositoryProvider).watchVet(vetId);
});
