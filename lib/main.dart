import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/router/firebase_initialized_provider.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/remote_config_service.dart';
import 'firebase_options.dart';
import 'presentation/app/jeevamitra_app.dart';

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized when this runs in the background isolate.
  debugPrint('[FCM Background] ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Hive local storage
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveBoxSettings);
  await Hive.openBox(AppConstants.hiveBoxCache);

  // Firebase — graceful fallback if google-services.json is missing
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    // Crashlytics
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Analytics
    await FirebaseAnalytics.instance
        .setAnalyticsCollectionEnabled(!kDebugMode);

    // Performance monitoring
    await FirebasePerformance.instance
        .setPerformanceCollectionEnabled(!kDebugMode);

    // Remote config — fetch defaults + server values before UI starts
    await RemoteConfigService().init();

    firebaseInitialized = true;
  } catch (e) {
    debugPrint('[JeevaMitra] Firebase not configured: $e');
    debugPrint('[JeevaMitra] Run: flutterfire configure --project=YOUR_PROJECT_ID');
  }

  // Local notifications — must be initialized before runApp so the plugin
  // is ready when FCM foreground messages arrive.
  await LocalNotificationService().init();

  runApp(
    ProviderScope(
      overrides: [
        firebaseInitializedProvider.overrideWithValue(firebaseInitialized),
      ],
      child: const JeevaMitraApp(),
    ),
  );
}
