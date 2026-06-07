import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/local_notification_service.dart';

/// Emits the GoRouter path payload whenever the user taps a local notification.
/// `JeevaMitraApp` listens to this and calls `router.push(payload)`.
final notificationTapProvider = StreamProvider<String?>((ref) {
  return LocalNotificationService().tappedPayload;
});
