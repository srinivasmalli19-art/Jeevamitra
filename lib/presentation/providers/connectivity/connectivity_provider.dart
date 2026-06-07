import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/connectivity_service.dart';

final _connectivityServiceProvider =
    Provider<ConnectivityService>((_) => ConnectivityService());

/// Streams `true` when online, `false` when offline.
/// Seeds with the current connectivity state immediately.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(_connectivityServiceProvider);
  yield await service.isConnected;
  yield* service.onConnectivityChanged;
});

/// Flat bool — `true` while online (optimistic default before first emit).
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).valueOrNull ?? true;
});
