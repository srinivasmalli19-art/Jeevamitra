import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/firebase_constants.dart';
import '../constants/route_constants.dart';
import 'local_notification_service.dart';

class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  final _messaging = FirebaseMessaging.instance;

  /// Call once after user is authenticated. Stores FCM token in Firestore.
  Future<void> init(String userId) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      // Android 13+ requires explicit permission which is handled above.
      // iOS APNs token is fetched automatically when we call getToken.
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(userId, token);

      _messaging.onTokenRefresh.listen((t) => _saveToken(userId, t));

      // Show local notification when FCM message arrives while app is open.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    } catch (e) {
      debugPrint('[FCM] init error: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;
    final payload = _routeFromData(message.data);
    LocalNotificationService().show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: notif.title ?? 'JeevaMitra',
      body: notif.body ?? '',
      payload: payload,
    );
  }

  /// Derives a GoRouter path from FCM data map.
  /// Expects `data['route']` (explicit path) or `data['bookingId']` + `data['role']`.
  String _routeFromData(Map<String, dynamic> data) {
    final explicit = data['route'] as String?;
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final bookingId = data['bookingId'] as String?;
    final role = data['role'] as String?;
    if (bookingId != null && role != null) {
      return RouteConstants.bookingDetail(role, bookingId);
    }

    return RouteConstants.notifications;
  }

  Future<void> _saveToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.users)
          .doc(userId)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FCM] token save error: $e');
    }
  }

  /// Remove token on sign-out so user stops receiving push notifications.
  Future<void> clearToken(String userId) async {
    try {
      await _messaging.deleteToken();
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.users)
          .doc(userId)
          .update({'fcmToken': FieldValue.delete()});
    } catch (e) {
      debugPrint('[FCM] clearToken error: $e');
    }
  }

  Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<RemoteMessage?> get initialMessage =>
      _messaging.getInitialMessage();
}
