import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jeevamitra/core/services/local_notification_service.dart';
import 'package:jeevamitra/presentation/providers/notifications/notification_tap_provider.dart';

void main() {
  group('notificationTapProvider', () {
    test('is backed by the LocalNotificationService singleton without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Constructing/reading the provider must not touch any platform
      // channel — LocalNotificationService only does that in init()/show(),
      // not in its constructor or the tappedPayload getter.
      expect(() => container.read(notificationTapProvider), returnsNormally);
      expect(LocalNotificationService().tappedPayload, isA<Stream<String?>>());
    });
  });

  group('notification-tap navigation guard (same pattern JeevaMitraApp.build uses)', () {
    // JeevaMitraApp listens to notificationTapProvider and does:
    //   final payload = next.valueOrNull;
    //   if (payload == null || payload.isEmpty) return;
    //   try { router.push(payload); } catch (_) {}
    // Replicated here against a minimal router so the guard logic itself is
    // exercised without booting the full app (which requires a live
    // Firebase app for its other providers).
    Widget buildHarness(GoRouter router, StreamController<String?> tapEvents) {
      return ProviderScope(
        overrides: [
          notificationTapProvider.overrideWith((ref) => tapEvents.stream),
        ],
        child: Consumer(builder: (context, ref, _) {
          ref.listen<AsyncValue<String?>>(notificationTapProvider, (_, next) {
            final payload = next.valueOrNull;
            if (payload == null || payload.isEmpty) return;
            try {
              router.push(payload);
            } catch (_) {
              // Ignore navigation errors (e.g. route not found)
            }
          });
          return MaterialApp.router(routerConfig: router);
        }),
      );
    }

    testWidgets('a booking-detail payload navigates to that route', (tester) async {
      final tapEvents = StreamController<String?>.broadcast();
      addTearDown(tapEvents.close);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
        GoRoute(
          path: '/farmer/bookings/:bookingId',
          builder: (_, state) =>
              Scaffold(body: Text('booking:${state.pathParameters['bookingId']}')),
        ),
      ]);

      await tester.pumpWidget(buildHarness(router, tapEvents));
      await tester.pump();

      tapEvents.add('/farmer/bookings/b123');
      await tester.pumpAndSettle();

      expect(find.text('booking:b123'), findsOneWidget);
    });

    testWidgets('a null payload does not navigate', (tester) async {
      final tapEvents = StreamController<String?>.broadcast();
      addTearDown(tapEvents.close);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
      ]);

      await tester.pumpWidget(buildHarness(router, tapEvents));
      await tester.pump();

      tapEvents.add(null);
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('an empty-string payload does not navigate', (tester) async {
      final tapEvents = StreamController<String?>.broadcast();
      addTearDown(tapEvents.close);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
      ]);

      await tester.pumpWidget(buildHarness(router, tapEvents));
      await tester.pump();

      tapEvents.add('');
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('a payload matching no route is swallowed, not crashed', (tester) async {
      final tapEvents = StreamController<String?>.broadcast();
      addTearDown(tapEvents.close);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
      ]);

      await tester.pumpWidget(buildHarness(router, tapEvents));
      await tester.pump();

      tapEvents.add('/this/route/does/not/exist');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
