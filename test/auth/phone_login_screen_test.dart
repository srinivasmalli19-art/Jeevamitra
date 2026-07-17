import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jeevamitra/core/constants/route_constants.dart';
import 'package:jeevamitra/generated/l10n/app_localizations.dart';
import 'package:jeevamitra/presentation/providers/auth/auth_provider.dart';
import 'package:jeevamitra/presentation/screens/auth/phone_login_screen.dart';
import 'package:mocktail/mocktail.dart';

class _DummyAuth extends Mock implements FirebaseAuth {}

/// A stand-in AuthNotifier that never touches real Firebase — it records
/// what was asked of it and returns a canned result, so the screen's own
/// navigation/error-handling logic can be tested in isolation.
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({this.sendOtpResult})
      : super(auth: _DummyAuth(), firestore: FakeFirebaseFirestore());

  final String? sendOtpResult;
  String? lastPhoneRequested;

  @override
  Future<String?> sendOtp(String phone) async {
    lastPhoneRequested = phone;
    return sendOtpResult;
  }
}

Future<void> _pump(WidgetTester tester, FakeAuthNotifier fakeNotifier) async {
  final router = GoRouter(
    initialLocation: RouteConstants.phoneLogin,
    routes: [
      GoRoute(
        path: RouteConstants.phoneLogin,
        builder: (_, __) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.otpVerification,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Scaffold(body: Text('OTP_SCREEN:${extra?['phone']}'));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authNotifierProvider.overrideWith((ref) => fakeNotifier)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en', 'IN'),
        supportedLocales: const [Locale('en', 'IN')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PhoneLoginScreen', () {
    testWidgets('renders the +91 prefix and a Send OTP button', (tester) async {
      await _pump(tester, FakeAuthNotifier(sendOtpResult: null));
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('blocks submission and shows a validation error for a short number',
        (tester) async {
      final fake = FakeAuthNotifier(sendOtpResult: null);
      await _pump(tester, fake);

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Enter valid 10-digit mobile number'), findsOneWidget);
      expect(fake.lastPhoneRequested, isNull,
          reason: 'sendOtp must not be called for an invalid phone number');
    });

    testWidgets('on success, calls sendOtp with a +91-prefixed number and navigates to OTP screen',
        (tester) async {
      final fake = FakeAuthNotifier(sendOtpResult: null);
      await _pump(tester, fake);

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(fake.lastPhoneRequested, '+919876543210');
      expect(find.text('OTP_SCREEN:+919876543210'), findsOneWidget);
    });

    testWidgets('on failure, shows the real error in a SnackBar and does NOT navigate '
        '(this is the exact case the OTP bug used to hide)', (tester) async {
      final fake = FakeAuthNotifier(sendOtpResult: 'Play Integrity attestation failed.');
      await _pump(tester, fake);

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Play Integrity attestation failed.'), findsOneWidget);
      expect(find.textContaining('OTP_SCREEN:'), findsNothing);
    });
  });
}
