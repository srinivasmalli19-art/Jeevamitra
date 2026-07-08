import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../generated/l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/notifications/notification_providers.dart';
import '../providers/notifications/notification_tap_provider.dart';
import '../widgets/common/offline_banner.dart';

class JeevaMitraApp extends ConsumerWidget {
  const JeevaMitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    // Trigger FCM init whenever auth state has a logged-in user
    ref.watch(fcmInitProvider);

    // Navigate when user taps a local notification
    ref.listen<AsyncValue<String?>>(notificationTapProvider, (_, next) {
      final payload = next.valueOrNull;
      if (payload == null || payload.isEmpty) return;
      try {
        router.push(payload);
      } catch (_) {
        // Ignore navigation errors (e.g. route not found)
      }
    });

    return MaterialApp.router(
      title: 'JeevaMitra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: const [
        Locale('te', 'IN'),
        Locale('hi', 'IN'),
        Locale('en', 'IN'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => OfflineBanner(child: child ?? const SizedBox()),
    );
  }
}
