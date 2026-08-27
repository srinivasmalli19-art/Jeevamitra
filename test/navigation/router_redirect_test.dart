// Exercises the real routerProvider / redirect logic from
// lib/core/router/app_router.dart — the auth-gate that decides whether a
// user lands on the login screen, role selection, profile setup, or their
// dashboard. Farmer/shepherd dashboard screens themselves read Firestore
// providers that call FirebaseAuth.instance directly and are NOT safe to
// fully build without a real Firebase app, so those destinations are
// asserted by matched *location* only (not full render) — full dashboard
// rendering is covered by the integration test with mocked platform
// channels instead.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jeevamitra/core/constants/route_constants.dart';
import 'package:jeevamitra/core/router/app_router.dart';
import 'package:jeevamitra/core/router/firebase_initialized_provider.dart';
import 'package:jeevamitra/generated/l10n/app_localizations.dart';
import 'package:jeevamitra/presentation/providers/auth/auth_provider.dart';
import 'package:jeevamitra/presentation/providers/auth/user_doc.dart';
import 'package:mocktail/mocktail.dart';

class MockUser extends Mock implements User {}

Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  required bool firebaseReady,
  required AsyncValue<User?> authState,
  required AsyncValue<UserDoc?> userDocState,
  String initialLocation = RouteConstants.splash,
}) async {
  late GoRouter router;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseInitializedProvider.overrideWithValue(firebaseReady),
        authStateProvider.overrideWith((ref) => authState.when(
              data: Stream.value,
              loading: () => const Stream<User?>.empty(),
              error: (e, st) => Stream<User?>.error(e, st),
            )),
        currentUserDocProvider.overrideWith((ref) => userDocState.when(
              data: Stream.value,
              loading: () => const Stream<UserDoc?>.empty(),
              error: (e, st) => Stream<UserDoc?>.error(e, st),
            )),
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
  // pumpAndSettle() is unusable here for two independent reasons: (1)
  // SplashScreen's own Future.delayed(2200ms) gate plus its one-shot fade
  // AnimationController occasionally leaves it spinning past pumpAndSettle's
  // internal timeout, and (2) redirects that land on the farmer/shepherd
  // dashboards build screens that call FirebaseAuth.instance directly and
  // throw "no Firebase App" outside a real Firebase context. Bounded manual
  // pumps get the router's *matched location* (resolved before the
  // destination widget is built) without either problem — full dashboard
  // rendering is covered by the integration test instead.
  //
  // Splash is always the router's real initialLocation in this app (any
  // deep link — including a notification tap — is processed after splash's
  // own gate resolves first), so every scenario here lets splash's
  // Future.delayed(2200ms) resolve BEFORE simulating a deep link, instead of
  // racing a manual router.go() against splash's pending timer.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 2300));
  await tester.pump();
  if (initialLocation != RouteConstants.splash) {
    router.go(initialLocation);
    await tester.pump();
    await tester.pump();
  }
  tester.takeException(); // consume any expected build error from a heavy destination screen
  return router;
}

String _currentPath(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  group('router redirect — Firebase not ready yet', () {
    testWidgets('stays on splash until Firebase finishes initializing', (tester) async {
      final router = await _pumpRouter(
        tester,
        firebaseReady: false,
        authState: const AsyncValue.loading(),
        userDocState: const AsyncValue.loading(),
      );
      expect(_currentPath(router), RouteConstants.splash);
    });
  });

  group('router redirect — unauthenticated', () {
    testWidgets(
        'a fresh unauthenticated user lands on language-select, not phone login — '
        'FINDING: SplashScreen._navigate() branches only on currentUserDocProvider, '
        'which is also null for an unauthenticated user (see currentUserDocProvider in '
        'auth_provider.dart: "if (user == null) return Stream.value(null);"), so it '
        'cannot tell "never signed in" apart from "signed in, no Firestore doc yet" — '
        'both take the doc-is-null branch and go to languageSelect. The app_router.dart '
        'redirect guard permits this (onboarding routes are allowed pre-auth), so it is '
        'not a crash or a security hole, but it does mean AppConstants.prefOnboarded '
        '(defined in app_constants.dart, never read or written anywhere) is dead code — '
        'there is no "skip onboarding for a returning-but-not-yet-logged-in user" path.',
        (tester) async {
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: const AsyncValue.data(null),
        userDocState: const AsyncValue.data(null),
      );
      expect(_currentPath(router), RouteConstants.languageSelect);
    });

    testWidgets('phone login itself is reachable and is not redirected away pre-auth',
        (tester) async {
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: const AsyncValue.data(null),
        userDocState: const AsyncValue.data(null),
        initialLocation: RouteConstants.phoneLogin,
      );
      expect(_currentPath(router), RouteConstants.phoneLogin);
    });

    testWidgets(
        'a direct deep link to the farmer dashboard is redirected to phone login '
        'instead of exposing the dashboard to an unauthenticated user', (tester) async {
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: const AsyncValue.data(null),
        userDocState: const AsyncValue.data(null),
        initialLocation: RouteConstants.farmerDashboard,
      );
      expect(_currentPath(router), RouteConstants.phoneLogin);
    });

    testWidgets('a direct deep link to the shepherd dashboard is also blocked', (tester) async {
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: const AsyncValue.data(null),
        userDocState: const AsyncValue.data(null),
        initialLocation: RouteConstants.shepherdDashboard,
      );
      expect(_currentPath(router), RouteConstants.phoneLogin);
    });
  });

  group('router redirect — authenticated, no Firestore user doc yet', () {
    testWidgets('is sent to role selection right after OTP verification', (tester) async {
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: AsyncValue.data(MockUser()),
        userDocState: const AsyncValue.data(null),
      );
      expect(_currentPath(router), RouteConstants.roleSelect);
    });
  });

  group('router redirect — authenticated with an incomplete profile', () {
    testWidgets('is sent to profile setup', (tester) async {
      final incompleteDoc = const UserDoc(
        uid: 'uid-1',
        phone: '+919876543210',
        role: 'farmer',
        name: '',
        isProfileComplete: false,
      );
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: AsyncValue.data(MockUser()),
        userDocState: AsyncValue.data(incompleteDoc),
      );
      expect(_currentPath(router), RouteConstants.profileSetup);
    });
  });

  group('router redirect — fully onboarded', () {
    testWidgets(
        'Sprint 4: a farmer landing on splash is routed into the Universal '
        'Shell at the canonical /home path (previously the role-specific '
        '/farmer/dashboard — the shell is now identical for every role)',
        (tester) async {
      final completeDoc = const UserDoc(
        uid: 'uid-1',
        phone: '+919876543210',
        role: 'farmer',
        name: 'Ravi',
        village: 'Narasaraopet',
        district: 'Guntur',
        isProfileComplete: true,
      );
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: AsyncValue.data(MockUser()),
        userDocState: AsyncValue.data(completeDoc),
      );
      expect(_currentPath(router), RouteConstants.home);
    });

    testWidgets(
        'Sprint 4: the legacy /farmer/lands route still resolves (not '
        'broken) for a shepherd-role user — it now redirects into the '
        'Universal Shell\'s canonical /lands tab rather than rendering '
        'standalone, since Lands is one shared tab for every profile',
        (tester) async {
      final shepherdDoc = const UserDoc(
        uid: 'uid-2',
        phone: '+919876543211',
        role: 'shepherd',
        name: 'Suresh',
        village: 'Vijayawada',
        district: 'Krishna',
        isProfileComplete: true,
      );
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: AsyncValue.data(MockUser()),
        userDocState: AsyncValue.data(shepherdDoc),
        initialLocation: RouteConstants.farmerLands,
      );
      expect(_currentPath(router), RouteConstants.lands);
    });

    testWidgets(
        'Sprint 4: the legacy /shepherd/vets route still resolves for a '
        'farmer-role user, redirecting into the canonical /vets tab',
        (tester) async {
      final farmerDoc = const UserDoc(
        uid: 'uid-3',
        phone: '+919876543212',
        role: 'farmer',
        name: 'Ravi',
        village: 'Narasaraopet',
        district: 'Guntur',
        isProfileComplete: true,
      );
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: AsyncValue.data(MockUser()),
        userDocState: AsyncValue.data(farmerDoc),
        initialLocation: RouteConstants.shepherdVets,
      );
      expect(_currentPath(router), RouteConstants.vets);
    });

    testWidgets(
        'Sprint 4: a "both"-profile user (backendRole farmer, profileType '
        'both) reaching the legacy /shepherd/discover route also lands on '
        'the canonical /lands tab', (tester) async {
      final bothDoc = const UserDoc(
        uid: 'uid-4',
        phone: '+919876543213',
        role: 'farmer',
        name: 'Lakshmi',
        village: 'Guntur',
        district: 'Guntur',
        isProfileComplete: true,
        profileType: 'both',
      );
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: AsyncValue.data(MockUser()),
        userDocState: AsyncValue.data(bothDoc),
        initialLocation: RouteConstants.shepherdDiscover,
      );
      expect(_currentPath(router), RouteConstants.lands);
    });
  });

  group('router redirect — Universal Shell (Sprint 4)', () {
    const farmerDoc = UserDoc(
      uid: 'uid-shell-farmer',
      phone: '+919876543220',
      role: 'farmer',
      name: 'Ravi',
      village: 'Narasaraopet',
      district: 'Guntur',
      isProfileComplete: true,
      profileType: 'fodderLandProvider',
    );
    const shepherdDoc = UserDoc(
      uid: 'uid-shell-shepherd',
      phone: '+919876543221',
      role: 'shepherd',
      name: 'Suresh',
      village: 'Vijayawada',
      district: 'Krishna',
      isProfileComplete: true,
      profileType: 'livestockOwner',
    );
    const bothDoc = UserDoc(
      uid: 'uid-shell-both',
      phone: '+919876543222',
      role: 'farmer',
      name: 'Lakshmi',
      village: 'Guntur',
      district: 'Guntur',
      isProfileComplete: true,
      profileType: 'both',
    );

    const canonicalTabs = [
      RouteConstants.home,
      RouteConstants.lands,
      RouteConstants.bookings,
      RouteConstants.vets,
      RouteConstants.profile,
    ];

    for (final entry in {
      'Fodder Land Provider': farmerDoc,
      'Livestock Owner': shepherdDoc,
      'Both': bothDoc,
    }.entries) {
      for (final tab in canonicalTabs) {
        testWidgets(
            '${entry.key} can open the $tab tab directly (not redirected '
            'away — Universal Access: identical navigation for every '
            'profile)', (tester) async {
          final router = await _pumpRouter(
            tester,
            firebaseReady: true,
            authState: AsyncValue.data(MockUser()),
            userDocState: AsyncValue.data(entry.value),
            initialLocation: tab,
          );
          expect(_currentPath(router), tab);
        });
      }
    }

    testWidgets(
        'an unauthenticated deep link to any canonical shell tab is blocked, '
        'same protection the old /farmer, /shepherd prefixes had',
        (tester) async {
      for (final tab in canonicalTabs) {
        final router = await _pumpRouter(
          tester,
          firebaseReady: true,
          authState: const AsyncValue.data(null),
          userDocState: const AsyncValue.data(null),
          initialLocation: tab,
        );
        expect(_currentPath(router), RouteConstants.phoneLogin);
      }
    });

    testWidgets(
        'every legacy farmer/shepherd shell route redirects into its '
        'canonical Universal Shell equivalent, so no old deep link/bookmark '
        'breaks', (tester) async {
      const expectedRedirects = {
        RouteConstants.farmerDashboard: RouteConstants.home,
        RouteConstants.shepherdDashboard: RouteConstants.home,
        RouteConstants.farmerLands: RouteConstants.lands,
        RouteConstants.shepherdDiscover: RouteConstants.lands,
        RouteConstants.farmerBookings: RouteConstants.bookings,
        RouteConstants.shepherdBookings: RouteConstants.bookings,
        RouteConstants.shepherdVets: RouteConstants.vets,
        RouteConstants.farmerProfile: RouteConstants.profile,
        RouteConstants.shepherdProfile: RouteConstants.profile,
      };
      for (final e in expectedRedirects.entries) {
        final router = await _pumpRouter(
          tester,
          firebaseReady: true,
          authState: AsyncValue.data(MockUser()),
          userDocState: AsyncValue.data(bothDoc),
          initialLocation: e.key,
        );
        expect(_currentPath(router), e.value, reason: 'redirect from ${e.key}');
      }
    });
  });

  group('router redirect — Choose Your Profile (pre-auth)', () {
    testWidgets('is reachable pre-auth and is not redirected away', (tester) async {
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: const AsyncValue.data(null),
        userDocState: const AsyncValue.data(null),
        initialLocation: RouteConstants.chooseProfile,
      );
      expect(_currentPath(router), RouteConstants.chooseProfile);
    });

    testWidgets('a fully onboarded user visiting it is redirected to their dashboard, '
        'not left stuck in onboarding', (tester) async {
      final completeDoc = const UserDoc(
        uid: 'uid-5',
        phone: '+919876543214',
        role: 'farmer',
        name: 'Ravi',
        village: 'Narasaraopet',
        district: 'Guntur',
        isProfileComplete: true,
      );
      final router = await _pumpRouter(
        tester,
        firebaseReady: true,
        authState: AsyncValue.data(MockUser()),
        userDocState: AsyncValue.data(completeDoc),
        initialLocation: RouteConstants.chooseProfile,
      );
      expect(_currentPath(router), RouteConstants.home);
    });
  });
}
