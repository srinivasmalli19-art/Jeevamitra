import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jeevamitra/domain/entities/user_profile_type.dart';
import 'package:jeevamitra/generated/l10n/app_localizations.dart';
import 'package:jeevamitra/presentation/providers/auth/auth_provider.dart';
import 'package:jeevamitra/presentation/providers/auth/user_doc.dart';
import 'package:jeevamitra/presentation/providers/onboarding/profile_type_provider.dart';
import 'package:jeevamitra/presentation/screens/auth/otp_verification_screen.dart';
import 'package:mocktail/mocktail.dart';

class _DummyAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({this.verifyResult = true, this.sendOtpResult})
      : super(auth: _DummyAuth(), firestore: FakeFirebaseFirestore());

  final bool verifyResult;
  final String? sendOtpResult;
  String? lastOtpVerified;
  int resendCallCount = 0;
  Map<String, dynamic>? lastCreateUserDocArgs;
  bool createUserDocResult = true;

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

  @override
  Future<bool> createUserDoc({
    required String uid,
    required String phone,
    required String role,
    required String name,
    String? village,
    String? district,
    String preferredLanguage = 'te',
    String? profileType,
  }) async {
    lastCreateUserDocArgs = {
      'uid': uid,
      'phone': phone,
      'role': role,
      'name': name,
      'profileType': profileType,
    };
    return createUserDocResult;
  }
}

Future<void> _pump(
  WidgetTester tester,
  FakeAuthNotifier fakeNotifier, {
  List<Override> extraOverrides = const [],
}) async {
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
      GoRoute(
        path: '/auth/setup',
        builder: (_, __) => const Scaffold(body: Text('PROFILE_SETUP_SCREEN')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) => fakeNotifier),
        ...extraOverrides,
      ],
      // In production, authStateProvider/currentUserDocProvider are always
      // already "warm" by the time OtpVerificationScreen is reached — the
      // router's own _RouterNotifier subscribes to both from app startup.
      // _verify() reads them synchronously via ref.read(), so this Consumer
      // reproduces that same early subscription here — without it, a
      // freshly-overridden Stream.value(...) hasn't delivered its first
      // event yet by the time _verify() runs, and ref.read() sees
      // AsyncLoading instead of the mocked value.
      child: Consumer(
        builder: (context, ref, _) {
          if (extraOverrides.isNotEmpty) {
            ref.watch(authStateProvider);
            ref.watch(currentUserDocProvider);
          }
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
        },
      ),
    ),
  );
  // One settle-free pump: the countdown Timer.periodic never "settles",
  // so pumpAndSettle would hang here.
  await tester.pump();
  if (extraOverrides.isNotEmpty) {
    // Let the warmed-up providers' overridden streams deliver their first
    // event before the test starts interacting with the screen.
    await tester.pump();
  }
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

  group('OtpVerificationScreen — pre-chosen profile (Profile Restructure)', () {
    testWidgets(
        'with a pending profile selection, creates the user doc automatically '
        'and goes straight to Profile Setup — no role-select screen shown',
        (tester) async {
      final fake = FakeAuthNotifier(verifyResult: true);
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-new');
      when(() => mockUser.phoneNumber).thenReturn('+919876543210');

      await _pump(
        tester,
        fake,
        extraOverrides: [
          pendingProfileTypeProvider
              .overrideWith((ref) => UserProfileType.livestockOwner),
          authStateProvider.overrideWith((ref) => Stream.value(mockUser)),
          currentUserDocProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify OTP'));
      await tester.pump();
      await tester.pump();

      expect(fake.lastCreateUserDocArgs, isNotNull);
      expect(fake.lastCreateUserDocArgs!['uid'], 'uid-new');
      expect(fake.lastCreateUserDocArgs!['role'], 'shepherd'); // livestockOwner's backend role
      expect(fake.lastCreateUserDocArgs!['profileType'], 'livestockOwner');
      expect(find.text('PROFILE_SETUP_SCREEN'), findsOneWidget);
      expect(find.text('ROLE_SELECT_SCREEN'), findsNothing);
    });

    testWidgets(
        'a pending selection is not applied over an already-existing '
        'account — falls back to role-select instead of overwriting it',
        (tester) async {
      final fake = FakeAuthNotifier(verifyResult: true);
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('uid-existing');
      when(() => mockUser.phoneNumber).thenReturn('+919876543210');
      const existingDoc = UserDoc(
        uid: 'uid-existing',
        phone: '+919876543210',
        role: 'farmer',
        name: 'Ravi',
        village: 'Narasaraopet',
        district: 'Guntur',
        isProfileComplete: true,
      );

      await _pump(
        tester,
        fake,
        extraOverrides: [
          pendingProfileTypeProvider
              .overrideWith((ref) => UserProfileType.fodderLandProvider),
          authStateProvider.overrideWith((ref) => Stream.value(mockUser)),
          currentUserDocProvider.overrideWith((ref) => Stream.value(existingDoc)),
        ],
      );

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify OTP'));
      await tester.pump();
      await tester.pump();

      expect(fake.lastCreateUserDocArgs, isNull);
      expect(find.text('ROLE_SELECT_SCREEN'), findsOneWidget);
    });
  });
}
