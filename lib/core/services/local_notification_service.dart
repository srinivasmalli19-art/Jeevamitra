import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<String?>.broadcast();

  static const _channelId = 'jm_default';
  static const _channelName = 'JeevaMitra Notifications';
  static const _channelDesc = 'Booking updates, disease alerts, and more';

  Future<void> init() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _tapController.add(details.payload);
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (_) {
      // Notifications are non-critical; swallow errors silently.
    }
  }

  /// Emits the payload string whenever the user taps a notification.
  Stream<String?> get tappedPayload => _tapController.stream;
}
