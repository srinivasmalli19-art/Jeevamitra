// Widget-level tests for the unified Home Dashboard (Sprint 5).
//
// HomeDashboardScreen's section widgets read several Firestore-backed
// StreamProviders (myFarmsProvider, nearbyFarmsProvider, etc.) that call
// FirebaseAuth.instance directly — not safe to hit without a real Firebase
// app (see router_redirect_test.dart's own comment on this same
// constraint). Every one of those providers is overridden here with a
// fixed empty/stub value so the screen renders fully offline; what's under
// test is purely the *composition* — which section widgets get built, in
// what order, for which profile — not their live data content.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jeevamitra/core/constants/route_constants.dart';
import 'package:jeevamitra/core/services/location_service.dart';
import 'package:jeevamitra/generated/l10n/app_localizations.dart';
import 'package:jeevamitra/presentation/providers/alerts/disease_alert_providers.dart';
import 'package:jeevamitra/presentation/providers/auth/auth_provider.dart';
import 'package:jeevamitra/presentation/providers/auth/user_doc.dart';
import 'package:jeevamitra/presentation/providers/booking/booking_providers.dart';
import 'package:jeevamitra/presentation/providers/farm/farm_providers.dart';
import 'package:jeevamitra/presentation/providers/location_provider.dart';
import 'package:jeevamitra/presentation/providers/notifications/notification_providers.dart';
import 'package:jeevamitra/presentation/providers/vet/vet_providers.dart';
import 'package:jeevamitra/presentation/screens/shell/home/home_dashboard_screen.dart';
import 'package:jeevamitra/presentation/screens/shell/home/home_sections.dart';
import 'package:jeevamitra/presentation/screens/shell/home/home_stats_grid.dart';
import 'package:jeevamitra/presentation/screens/shell/home/quick_action_button.dart';
import 'package:jeevamitra/presentation/widgets/common/dashboard_stat_card.dart';

List<Override> _stubDataOverrides(UserDoc doc) => [
      currentUserDocProvider.overrideWith((ref) => Stream.value(doc)),
      notificationsProvider.overrideWith((ref) => Stream.value(const [])),
      myFarmsProvider.overrideWith((ref) => Stream.value(const [])),
      farmerBookingsProvider.overrideWith((ref) => Stream.value(const [])),
      shepherdBookingsProvider.overrideWith((ref) => Stream.value(const [])),
      nearbyFarmsProvider
          .overrideWith((ref, params) => Stream.value(const [])),
      nearbyVetsProvider.overrideWith((ref, params) => Stream.value(const [])),
      nearbyAlertsProvider
          .overrideWith((ref, params) => Stream.value(const [])),
      // Fixed non-null location so the "location required" empty-state
      // branch is skipped and the nearby-* sections actually mount (their
      // family providers above, not a real location fetch).
      locationProvider.overrideWith(
        (ref) => _FixedLocationNotifier(
          const LocationResult(lat: 16.5, lng: 80.6),
        ),
      ),
    ];

class _FixedLocationNotifier extends LocationNotifier {
  _FixedLocationNotifier(LocationResult result) {
    state = AsyncValue.data(result);
  }
}

Future<void> _pumpHome(
  WidgetTester tester,
  UserDoc doc, {
  Map<String, WidgetBuilder> extraRoutes = const {},
}) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeDashboardScreen()),
      for (final entry in extraRoutes.entries)
        GoRoute(path: entry.key, builder: (context, __) => entry.value(context)),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: _stubDataOverrides(doc),
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
  await tester.pump();
  await tester.pump();
}

const _livestockOwnerDoc = UserDoc(
  uid: 'uid-lo',
  phone: '+919876543210',
  role: 'shepherd',
  name: 'Suresh',
  village: 'Vijayawada',
  district: 'Krishna',
  isProfileComplete: true,
  profileType: 'livestockOwner',
);

const _fodderProviderDoc = UserDoc(
  uid: 'uid-flp',
  phone: '+919876543211',
  role: 'farmer',
  name: 'Ravi',
  village: 'Narasaraopet',
  district: 'Guntur',
  isProfileComplete: true,
  profileType: 'fodderLandProvider',
);

const _bothDoc = UserDoc(
  uid: 'uid-both',
  phone: '+919876543212',
  role: 'farmer',
  name: 'Lakshmi',
  village: 'Guntur',
  district: 'Guntur',
  isProfileComplete: true,
  profileType: 'both',
);

// No profileType stored — a pre-Profile-Restructure account.
const _legacyFarmerDoc = UserDoc(
  uid: 'uid-legacy-farmer',
  phone: '+919876543213',
  role: 'farmer',
  name: 'Krishna',
  village: 'Tenali',
  district: 'Guntur',
  isProfileComplete: true,
);

const _legacyShepherdDoc = UserDoc(
  uid: 'uid-legacy-shepherd',
  phone: '+919876543214',
  role: 'shepherd',
  name: 'Anjali',
  village: 'Eluru',
  district: 'West Godavari',
  isProfileComplete: true,
);

void main() {
  group('daypartGreetingLabel — pure function, time-independent tests', () {
    testWidgets('before noon returns the morning label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'IN')],
        home: Builder(builder: (context) {
          final loc = AppLocalizations.of(context);
          expect(
            daypartGreetingLabel(loc, now: DateTime(2026, 1, 1, 9)),
            loc.goodMorningLabel,
          );
          return const SizedBox();
        }),
      ));
    });

    testWidgets('afternoon (12:00-16:59) returns the afternoon label',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'IN')],
        home: Builder(builder: (context) {
          final loc = AppLocalizations.of(context);
          expect(
            daypartGreetingLabel(loc, now: DateTime(2026, 1, 1, 14)),
            loc.goodAfternoonLabel,
          );
          return const SizedBox();
        }),
      ));
    });

    testWidgets('evening (17:00+) returns the evening label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'IN')],
        home: Builder(builder: (context) {
          final loc = AppLocalizations.of(context);
          expect(
            daypartGreetingLabel(loc, now: DateTime(2026, 1, 1, 19)),
            loc.goodEveningLabel,
          );
          return const SizedBox();
        }),
      ));
    });
  });

  group('HomeDashboardScreen — Sprint 6A hierarchy', () {
    testWidgets('renders the compact header with the JeevaMitra brand',
        (tester) async {
      await _pumpHome(tester, _bothDoc);
      expect(find.text('JeevaMitra'), findsOneWidget);
    });

    testWidgets(
        'greeting ("Namaste, <name>") appears, using the real signed-in '
        'user\'s name — not a hard-coded one', (tester) async {
      await _pumpHome(tester, _bothDoc);
      expect(find.textContaining('Lakshmi'), findsWidgets);
      expect(find.textContaining('Ravi'), findsNothing);
    });

    testWidgets(
        'the old "Hello, <name>!" greeting string is gone from Home — '
        'replaced by the Namaste greeting below the header',
        (tester) async {
      await _pumpHome(tester, _bothDoc);
      expect(find.textContaining('Hello, Lakshmi'), findsNothing);
    });

    testWidgets('HomeStatsGrid renders with exactly 4 stat cards',
        (tester) async {
      await _pumpHome(tester, _bothDoc);
      expect(find.byType(HomeStatsGrid), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HomeStatsGrid),
          matching: find.byType(DashboardStatCard),
        ),
        findsNWidgets(4),
      );
    });

    testWidgets('QuickActionsSection renders exactly 4 compact actions',
        (tester) async {
      await _pumpHome(tester, _bothDoc);
      expect(
        find.descendant(
          of: find.byType(QuickActionsSection),
          matching: find.byType(QuickActionButton),
        ),
        findsNWidgets(4),
      );
    });

    testWidgets(
        'Quick Actions render below (after) HomeStatsGrid, matching the '
        'prototype hierarchy — stats first, then quick actions',
        (tester) async {
      await _pumpHome(tester, _bothDoc);
      final statsY = tester.getTopLeft(find.byType(HomeStatsGrid)).dy;
      final actionsY =
          tester.getTopLeft(find.byType(QuickActionsSection)).dy;
      expect(statsY, lessThan(actionsY));
    });

    testWidgets(
        'HomeStatsGrid renders above (before) the profile-priority content '
        'sections', (tester) async {
      await _pumpHome(tester, _bothDoc);
      final statsY = tester.getTopLeft(find.byType(HomeStatsGrid)).dy;
      final nearbyLandsY =
          tester.getTopLeft(find.byType(NearbyLandsSection)).dy;
      expect(statsY, lessThan(nearbyLandsY));
    });
  });

  group('HomeDashboardScreen — Universal Access: every section for every profile', () {
    for (final entry in {
      'Livestock Owner': _livestockOwnerDoc,
      'Fodder Land Provider': _fodderProviderDoc,
      'Both': _bothDoc,
    }.entries) {
      testWidgets(
          '${entry.key} sees all 5 content sections plus Quick Actions — '
          'none hidden by profile', (tester) async {
        await _pumpHome(tester, entry.value);

        expect(find.byType(QuickActionsSection), findsOneWidget);
        expect(find.byType(NearbyLandsSection), findsOneWidget);
        expect(find.byType(MyLandsSection), findsOneWidget);
        expect(find.byType(ActiveBookingsSection), findsOneWidget);
        expect(find.byType(NearbyVetsSection), findsOneWidget);
        expect(find.byType(DiseaseAlertsSection), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('HomeDashboardScreen — legacy accounts (no stored profileType)', () {
    testWidgets(
        'a legacy farmer-role account (profileType null) still renders a '
        'complete, valid dashboard via effectiveProfileType\'s role-based '
        'fallback — no crash, nothing missing', (tester) async {
      await _pumpHome(tester, _legacyFarmerDoc);

      expect(find.byType(QuickActionsSection), findsOneWidget);
      expect(find.byType(NearbyLandsSection), findsOneWidget);
      expect(find.byType(MyLandsSection), findsOneWidget);
      expect(find.byType(ActiveBookingsSection), findsOneWidget);
      expect(find.byType(NearbyVetsSection), findsOneWidget);
      expect(find.byType(DiseaseAlertsSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a legacy shepherd-role account (profileType null) also still '
        'renders a complete, valid dashboard', (tester) async {
      await _pumpHome(tester, _legacyShepherdDoc);

      expect(find.byType(QuickActionsSection), findsOneWidget);
      expect(find.byType(NearbyLandsSection), findsOneWidget);
      expect(find.byType(MyLandsSection), findsOneWidget);
      expect(find.byType(ActiveBookingsSection), findsOneWidget);
      expect(find.byType(NearbyVetsSection), findsOneWidget);
      expect(find.byType(DiseaseAlertsSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeDashboardScreen — existing navigation actions remain functional', () {
    testWidgets('"Find Land" Quick Action still navigates to the Lands tab',
        (tester) async {
      await _pumpHome(
        tester,
        _bothDoc,
        extraRoutes: {
          RouteConstants.lands: (_) => const Scaffold(body: Text('LANDS_TAB')),
        },
      );

      await tester.tap(find.text('Find Land'));
      await tester.pump();
      await tester.pump();

      expect(find.text('LANDS_TAB'), findsOneWidget);
    });

    testWidgets('"Post Land" Quick Action still navigates to Add Land',
        (tester) async {
      await _pumpHome(
        tester,
        _bothDoc,
        extraRoutes: {
          RouteConstants.farmerAddLand: (_) =>
              const Scaffold(body: Text('ADD_LAND_SCREEN')),
        },
      );

      // "Post Land" also appears as MyLandsSection's empty-state button —
      // scope to the Quick Actions block specifically to avoid ambiguity.
      await tester.tap(find.descendant(
        of: find.byType(QuickActionsSection),
        matching: find.text('Post Land'),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('ADD_LAND_SCREEN'), findsOneWidget);
    });

    testWidgets('"Find Vet" Quick Action still navigates to the Vets tab',
        (tester) async {
      await _pumpHome(
        tester,
        _bothDoc,
        extraRoutes: {
          RouteConstants.vets: (_) => const Scaffold(body: Text('VETS_TAB')),
        },
      );

      await tester.tap(find.text('Find Vet'));
      await tester.pump();
      await tester.pump();

      expect(find.text('VETS_TAB'), findsOneWidget);
    });
  });
}
