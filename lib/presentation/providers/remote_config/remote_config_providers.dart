import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/remote_config_service.dart';

/// Returns the already-initialized singleton. The actual fetch happens in
/// main.dart before runApp so this future resolves immediately.
final remoteConfigProvider = FutureProvider<RemoteConfigService>((ref) async {
  return RemoteConfigService();
});

/// Flat convenience providers — all fall back to safe defaults if config
/// hasn't loaded yet (e.g. Firebase unavailable in development).

final maxAnimalsProvider = Provider<int>((ref) {
  return ref.watch(remoteConfigProvider).valueOrNull?.maxAnimalsPerBooking ??
      200;
});

final minBookingDaysProvider = Provider<int>((ref) {
  return ref.watch(remoteConfigProvider).valueOrNull?.minBookingDays ?? 1;
});

final bookingRadiusKmProvider = Provider<double>((ref) {
  return ref.watch(remoteConfigProvider).valueOrNull?.bookingRadiusKm ?? 200.0;
});

final enableVoiceProvider = Provider<bool>((ref) {
  return ref.watch(remoteConfigProvider).valueOrNull?.enableVoice ?? true;
});

final enableAlertsProvider = Provider<bool>((ref) {
  return ref.watch(remoteConfigProvider).valueOrNull?.enableAlerts ?? true;
});

final maintenanceModeProvider = Provider<bool>((ref) {
  return ref.watch(remoteConfigProvider).valueOrNull?.maintenanceMode ?? false;
});

final maintenanceMessageProvider = Provider<String>((ref) {
  return ref.watch(remoteConfigProvider).valueOrNull?.maintenanceMessage ?? '';
});
