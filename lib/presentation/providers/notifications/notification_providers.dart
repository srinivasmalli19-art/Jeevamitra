import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/fcm_service.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../auth/auth_provider.dart';

// ── Repository ─────────────────────────────────────────────────────────────────

final notificationRepositoryProvider =
    Provider<NotificationRepository>((_) => NotificationRepository());

// ── Notifications stream ───────────────────────────────────────────────────────

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(notificationRepositoryProvider).watchNotifications(uid);
});

// ── Unread count ───────────────────────────────────────────────────────────────

final unreadCountProvider = Provider<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .valueOrNull
          ?.where((n) => !n.isRead)
          .length ??
      0;
});

// ── Notification actions notifier ──────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationNotifier(this._repo) : super(const AsyncValue.data(null));

  final NotificationRepository _repo;

  Future<void> markAsRead(String id) async {
    try {
      await _repo.markAsRead(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    state = const AsyncValue.loading();
    try {
      await _repo.markAllAsRead(uid);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.deleteNotification(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>(
  (ref) => NotificationNotifier(ref.read(notificationRepositoryProvider)),
);

// ── FCM initializer (call once when user is authenticated) ─────────────────────

final fcmInitProvider = Provider<void>((ref) {
  final userAsync = ref.watch(authStateProvider);
  userAsync.whenData((user) {
    if (user != null) {
      FcmService().init(user.uid);
      // Foreground message: silently store — backend writes to Firestore anyway
      FirebaseMessaging.onMessage.listen((_) {
        // Refresh the notifications stream (Firestore does this automatically)
      });
    }
  });
});
