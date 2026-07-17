import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jeevamitra/generated/l10n/app_localizations.dart';
import 'package:jeevamitra/presentation/providers/auth/auth_provider.dart';
import 'package:jeevamitra/presentation/screens/auth/otp_verification_screen.dart';
import 'package:mocktail/mocktail.dart';

class _DummyAuth extends Mock implements FirebaseAuth {}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({this.verifyResult = true, this.sendOtpResult})
      : super(auth: _DummyAuth(), firestore: FakeFirebaseFirestore());

  final bool verifyResult;
  final String? sendOtpResult;
  String? lastOtpVerified;
  int resendCallCount = 0;

  @override
  Future<bool> verifyOtp(String otp) async {
    lastOtpVerified = otp;
    return verifyResult;
  }

  @override
  Future<String?> sendOtp(String phone) async {
    resendCallCount++;
    return sendOtpResult;
  }
}

Future<void> _pump(WidgetTester tester, FakeAuthNotifier fakeNotifier) async {
  final router = GoRouter(
    initialLocation: '/auth/otp',
    routes: [
      GoRoute(
        path: '/auth/otp',
        builder: (_, __) => const OtpVerificationScreen(phone: '+919876543210'),
      ),
      GoRoute(
        path: '/auth/role',
        builder: (_, __) => const Scaffold(body: Text('ROLE_SELECT_SCREEN')),
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
  // One settle-free pump: the countdown Timer.periodic never "settles",
  // so pumpAndSettle would hang here.
  await tester.pump();
}

void main() {
  group('OtpVerificationScreen', () {
    testWidgets('shows the phone number the OTP was sent to', (tester) async {
      await _pump(tester, FakeAuthNotifier());
      expect(find.textContaining('+919876543210'), findsOneWidget);
    });

    testWidgets('resend is disabled during the 60s countdown', (tester) async {
      await _pump(tester, FakeAuthNotifier());
      expect(find.text('Resend OTP'), findsNothing);
      expect(find.text('Resend in 60s'), findsOneWidget);
    });

    testWidgets('resend becomes available once the countdown reaches zero', (tester) async {
      final fake = FakeAuthNotifier();
      await _pump(tester, fake);

      await tester.pump(const Duration(seconds: 61));
      await tester.pump();

      expect(find.text('Resend OTP'), findsOneWidget);

      await tester.tap(find.text('Resend OTP'));
      await tester.pump();
      expect(fake.resendCallCount, 1);
    });

    testWidgets('rejects a non-6-digit OTP without calling verifyOtp', (tester) async {
      final fake = FakeAuthNotifier();
      await _pump(tester, fake);

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Verify OTP'));
      await tester.pump();

      expect(find.text('Enter 6-digit OTP'), findsOneWidget);
      expect(fake.lastOtpVerified, isNull);
    });

    testWidgets('navigates to role-select on a correct OTP', (tester) async {
      final fake = FakeAuthNotifier(verifyResult: true);
      await _pump(tester, fake);

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify OTP'));
      await tester.pump();
      await tester.pump();

      expect(fake.lastOtpVerified, '123456');
      expect(find.text('ROLE_SELECT_SCREEN'), findsOneWidget);
    });

    testWidgets('shows an error and stays on screen for an incorrect OTP', (tester) async {
      final fake = FakeAuthNotifier(verifyResult: false);
      await _pump(tester, fake);

      await tester.enterText(find.byType(TextFormField), '000000');
      await tester.tap(find.text('Verify OTP'));
      await tester.pump();
      await tester.pump();

      expect(find.text('ROLE_SELECT_SCREEN'), findsNothing);
    });
  });
}
