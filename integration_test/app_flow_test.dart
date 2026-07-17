// End-to-end integration test for the auth funnel: splash -> phone login ->
// send OTP -> OTP verification -> role select. Runs on a REAL Flutter engine
// (via IntegrationTestWidgetsFlutterBinding, `-d macos`) driving the real
// router and real screens, rather than the lighter flutter_test harness.
//
// Uses a bare MaterialApp.router (same wiring as JeevaMitraApp minus its
// custom AppTheme) instead of JeevaMitraApp itself: AppTheme pulls Poppins
// from Google Fonts' CDN at runtime with no bundled local fallback, which
// this network-restricted test environment can't reach — a genuine finding
// in its own right (see the audit report), not a workaround for a test bug.
//
// Firebase itself is never initialized for real (no emulator suite is wired
// up in this project) — auth state and the OTP notifier are faked via
// Riverpod overrides, the same technique used in the individual screen
// tests, but this test drives every screen transition in one continuous run
// the way a human tester would.
import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jeevamitra/core/constants/app_constants.dart';
import 'package:jeevamitra/core/router/app_router.dart';
import 'package:jeevamitra/core/router/firebase_initialized_provider.dart';
import 'package:jeevamitra/generated/l10n/app_localizations.dart';
import 'package:jeevamitra/presentation/providers/auth/auth_provider.dart';
import 'package:jeevamitra/presentation/providers/auth/user_doc.dart';
import 'package:mocktail/mocktail.dart';

class _DummyAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {
  @override
  String get uid => 'integration-test-uid';
}

/// Drives the same phone -> OTP -> auth-state transition a real user would,
/// without touching any real Firebase backend: sendOtp/verifyOtp are canned,
/// and a successful verifyOtp pushes a user onto [authStateController] the
/// same way FirebaseAuth's real authStateChanges() stream would.
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this.authStateController)
      : super(auth: _DummyAuth(), firestore: FakeFirebaseFirestore());

  final StreamController<User?> authStateController;
  String? lastPhoneRequested;
  String? lastOtpVerified;

  @override
  Future<String?> sendOtp(String phone) async {
    lastPhoneRequested = phone;
    return null; // always "succeeds" for this happy-path flow
  }

  @override
  Future<bool> verifyOtp(String otp) async {
    lastOtpVerified = otp;
    if (otp != '123456') return false;
    authStateController.add(MockUser());
    return true;
  }
}

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required FakeAuthNotifier fakeNotifier,
  required StreamController<User?> authStateController,
}) async {
  // The default macOS test window (800x600) renders some full-width buttons
  // at an unexpected offset that misses hit-testing — force a phone-like
  // surface size so this test exercises layout close to the real target
  // platform instead of debugging a desktop-window-specific quirk.
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  late GoRouter router;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseInitializedProvider.overrideWithValue(true),
        authNotifierProvider.overrideWith((ref) => fakeNotifier),
        authStateProvider.overrideWith((ref) => authStateController.stream),
        currentUserDocProvider.overrideWith((ref) => Stream<UserDoc?>.value(null)),
      ],
      child: Consumer(builder: (context, ref, _) {
        router = ref.watch(routerProvider);
        return MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en', 'IN'),
          supportedLocales: const [Locale('en', 'IN')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      }),
    ),
  );
  // Bounded pumps, not pumpAndSettle(): splash has a one-shot 2200ms
  // Future.delayed gate, and the OTP screen has a genuinely-recurring
  // 60-tick Timer.periodic countdown — pumpAndSettle() would wait out
  // neither correctly (it either times out or spins for a full minute).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 2300)); // past splash's gate
  await tester.pump();
  return router;
}

/// Taps a button by invoking its onPressed callback directly rather than
/// simulating a pointer gesture. The macOS `integration_test` desktop
/// binding used here reports real-tap offsets outside its own render tree
/// bounds for these full-width buttons (a binding/coordinate-mapping quirk,
/// not an app layout bug — flutter_test's synthetic AutomatedTestWidgets
/// Binding used by the rest of this suite doesn't exhibit it). Invoking the
/// callback directly still exercises the exact same navigation logic under
/// test without depending on desktop pointer-event coordinate mapping.
Future<void> _tapButtonLabeled(WidgetTester tester, String label) async {
  final textFinder = find.textContaining(label);
  expect(textFinder, findsOneWidget);
  final buttonFinder = find.ancestor(
    of: textFinder,
    matching: find.byWidgetPredicate((w) =>
        w is ElevatedButton || w is OutlinedButton || w is TextButton),
  );
  expect(buttonFinder, findsOneWidget);
  final widget = tester.widget(buttonFinder);
  final onPressed = switch (widget) {
    ElevatedButton(:final onPressed) => onPressed,
    OutlinedButton(:final onPressed) => onPressed,
    TextButton(:final onPressed) => onPressed,
    _ => null,
  };
  expect(onPressed, isNotNull, reason: '$label button must be enabled');
  onPressed!();
  await tester.pump();
  await tester.pump();
}

/// A fresh unauthenticated user lands on language-select, not phone login
/// directly (see the router_redirect_test.dart finding: SplashScreen's own
/// navigate() branches only on currentUserDocProvider, which is also null
/// pre-auth). Get past language-select -> onboarding -> phone login, the
/// same minimum path any new user takes, using onboarding's "Skip" button
/// rather than paging through all three slides.
Future<void> _getPastOnboarding(WidgetTester tester) async {
  await _tapButtonLabeled(tester, 'Continue');
  await _tapButtonLabeled(tester, 'Skip');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // main.dart normally does this before runApp(); it's bypassed here since
  // this test builds the router directly, so localeProvider's Hive box read
  // would otherwise throw "Box not found".
  setUpAll(() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.hiveBoxSettings);
    await Hive.openBox(AppConstants.hiveBoxCache);
  });

  testWidgets(
    'full auth funnel: phone login -> send OTP -> verify OTP -> role select',
    (tester) async {
      final authStateController = StreamController<User?>.broadcast();
      addTearDown(authStateController.close);
      final fakeNotifier = FakeAuthNotifier(authStateController);

      await _pumpApp(tester, fakeNotifier: fakeNotifier, authStateController: authStateController);
      await _getPastOnboarding(tester);

      // 1. Landed on phone login.
      expect(find.text('Send OTP'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await _tapButtonLabeled(tester, 'Send OTP');

      expect(fakeNotifier.lastPhoneRequested, '+919876543210');

      // 2. OTP screen.
      expect(find.text('Verify OTP'), findsOneWidget);
      expect(find.textContaining('+919876543210'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).last, '123456');
      await _tapButtonLabeled(tester, 'Verify OTP');
      await tester.pump();

      expect(fakeNotifier.lastOtpVerified, '123456');

      // 3. Auth state flipped to signed-in with no user doc yet -> role select
      // is now showing (phone login / OTP screens may still exist deeper in
      // the Navigator's page stack for back-navigation — that's normal
      // go_router push/go behavior, not asserted away here).
      expect(find.textContaining('Farmer'), findsWidgets); // role-select offers Farmer/Shepherd
    },
  );

  testWidgets(
    'an incorrect OTP shows an error and keeps the user on the OTP screen',
    (tester) async {
      final authStateController = StreamController<User?>.broadcast();
      addTearDown(authStateController.close);
      final fakeNotifier = FakeAuthNotifier(authStateController);

      await _pumpApp(tester, fakeNotifier: fakeNotifier, authStateController: authStateController);
      await _getPastOnboarding(tester);

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await _tapButtonLabeled(tester, 'Send OTP');

      await tester.enterText(find.byType(TextFormField).last, '000000');
      await _tapButtonLabeled(tester, 'Verify OTP');
      await tester.pump();

      // Still on the OTP screen — never made it to role select. (The error
      // SnackBar's message can transiently match more than once mid-
      // transition, so this checks presence, not an exact count.)
      expect(find.text('Verify OTP'), findsOneWidget);
      expect(find.text('Invalid OTP. Please try again.'), findsWidgets);
    },
  );
}
