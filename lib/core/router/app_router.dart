import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_constants.dart';
import 'firebase_initialized_provider.dart';
import '../../presentation/providers/auth/auth_provider.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/language_select_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/onboarding/choose_profile_screen.dart';
import '../../presentation/providers/onboarding/profile_type_provider.dart';
import '../../presentation/screens/auth/phone_login_screen.dart';
import '../../presentation/screens/auth/otp_verification_screen.dart';
import '../../presentation/screens/auth/role_select_screen.dart';
import '../../presentation/screens/auth/profile_setup_screen.dart';
import '../../presentation/screens/farmer/lands/add_land_screen.dart';
import '../../presentation/screens/farmer/lands/availability_calendar_screen.dart';
import '../../presentation/screens/farmer/lands/land_detail_screen.dart';
import '../../presentation/screens/farmer/explore/farmer_explore_screen.dart';
import '../../presentation/screens/shepherd/discover/shepherd_land_detail_screen.dart';
import '../../presentation/screens/shepherd/vets/shepherd_vets_screen.dart';
import '../../presentation/screens/shepherd/vets/vet_detail_screen.dart';
import '../../presentation/screens/shepherd/explore_map/explore_map_screen.dart';
import '../../presentation/screens/shell/universal_shell.dart';
import '../../presentation/screens/shell/home/home_dashboard_screen.dart';
import '../../presentation/screens/shell/lands_tab_screen.dart';
import '../../presentation/screens/shell/bookings_tab_screen.dart';
import '../../presentation/screens/shell/profile_tab_screen.dart';
import '../../presentation/screens/shared/search/unified_search_screen.dart';
import '../../presentation/screens/shared/alerts/alert_detail_screen.dart';
import '../../presentation/screens/shared/alerts/alert_map_screen.dart';
import '../../presentation/screens/shared/alerts/my_reported_alerts_screen.dart';
import '../../presentation/screens/shared/emergency_screen.dart';
import '../../presentation/screens/shared/booking_detail_screen.dart';
import '../../presentation/screens/shared/assistant_screen.dart';
import '../../presentation/screens/shared/notifications_screen.dart';
import '../../presentation/screens/shared/settings_screen.dart';
import '../../presentation/screens/shared/map_picker_screen.dart';
import '../../presentation/screens/shared/report_alert_screen.dart';
import '../../presentation/screens/shepherd/bookings/book_land_screen.dart';

// ─── Router notifier ─────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(authStateProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue>(currentUserDocProvider, (_, __) => notifyListeners());
  }
}

// ─── Route redirect logic ─────────────────────────────────────────────────────

String? _redirect(Ref ref, GoRouterState state) {
  final loc = state.matchedLocation;

  // Declare location flags early so they are available in every branch below.
  final isOnSplash = loc == RouteConstants.splash;
  final isOnOnboarding = loc.startsWith('/onboarding');
  final isOnAuth = loc.startsWith('/auth');
  final isOnFarmer = loc.startsWith('/farmer');
  final isOnShepherd = loc.startsWith('/shepherd');
  // Universal Shell's own canonical routes need the same auth protection
  // the /farmer, /shepherd prefixes gave their old shell-branch routes.
  final isOnUniversalShell = loc == RouteConstants.home ||
      loc == RouteConstants.lands ||
      loc == RouteConstants.bookings ||
      loc == RouteConstants.vets ||
      loc == RouteConstants.profile;

  final firebaseReady = ref.read(firebaseInitializedProvider);
  if (!firebaseReady) return null; // stays on splash showing setup screen

  final authAsync = ref.read(authStateProvider);
  final userDocAsync = ref.read(currentUserDocProvider);

  final isLoading = authAsync.isLoading || userDocAsync.isLoading;
  if (isLoading) {
    // While auth is resolving, keep protected routes on splash to prevent
    // unauthenticated Firestore queries from firing.
    if (isOnFarmer || isOnShepherd || isOnUniversalShell) {
      return RouteConstants.splash;
    }
    return null;
  }

  final user = authAsync.valueOrNull;
  final doc = userDocAsync.valueOrNull;

  // Not logged in — also redirect from splash so sign-out doesn't leave user
  // stuck on a blank splash screen (happens when loading guard briefly parks
  // the user there and auth then settles to null).
  if (user == null) {
    if (isOnFarmer || isOnShepherd || isOnUniversalShell) {
      return RouteConstants.phoneLogin;
    }
    return null;
  }

  // Logged in but no doc yet (just verified OTP, going to role select)
  if (doc == null) {
    if (isOnAuth || isOnSplash) return null;
    return RouteConstants.roleSelect;
  }

  // Has doc but profile incomplete
  if (!doc.isProfileComplete) {
    if (loc == RouteConstants.profileSetup || isOnSplash) return null;
    return RouteConstants.profileSetup;
  }

  // Fully onboarded — redirect away from auth/onboarding screens into the
  // single Universal Shell (Sprint 4). Every profile lands in exactly the
  // same place; `doc.isFarmer`/`role` no longer decide the *route* here —
  // Home is a single unified dashboard (Sprint 5), and Lands/Bookings tab
  // content is still role-selected inside their own tab-screen wrappers.
  if (isOnAuth || isOnOnboarding || isOnSplash) {
    return RouteConstants.home;
  }

  // Universal Access: no permission-based redirect exists below this
  // point for any authenticated, fully-onboarded user — every profile
  // (Livestock Owner, Fodder Land Provider, Both) reaches every route
  // identically. `isOnFarmer`/`isOnShepherd` remain used only by the
  // earlier loading/unauthenticated guards above.
  return null;
}

// ─── Router provider ──────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    refreshListenable: notifier,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: false,
    redirect: (_, state) => _redirect(ref, state),
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => GoRouter.of(context).go(RouteConstants.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(path: RouteConstants.splash, builder: (_, __) => const SplashScreen()),

      // ── Onboarding ────────────────────────────────────────────────────────
      GoRoute(path: RouteConstants.languageSelect, builder: (_, __) => const LanguageSelectScreen()),
      GoRoute(path: RouteConstants.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: RouteConstants.chooseProfile,
        builder: (_, __) => ChooseProfileScreen(
          onContinue: (context, ref, selected) async {
            ref.read(pendingProfileTypeProvider.notifier).state = selected;
            context.go(RouteConstants.phoneLogin);
          },
        ),
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: RouteConstants.phoneLogin, builder: (_, __) => const PhoneLoginScreen()),
      GoRoute(
        path: RouteConstants.otpVerification,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpVerificationScreen(phone: extra?['phone'] ?? '');
        },
      ),
      GoRoute(path: RouteConstants.roleSelect, builder: (_, __) => const RoleSelectScreen()),
      GoRoute(path: RouteConstants.profileSetup, builder: (_, __) => const ProfileSetupScreen()),

      // ── Universal Shell (Sprint 4) ────────────────────────────────────────
      // One shell, five tabs, identical for every profile. Each tab reuses
      // an existing screen (not redesigned this sprint) chosen by the
      // tab-screen wrappers in presentation/screens/shell/.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => UniversalShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.home, builder: (_, __) => const HomeDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.lands, builder: (_, __) => const LandsTabScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.bookings, builder: (_, __) => const BookingsTabScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.vets, builder: (_, __) => const ShepherdVetsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.profile, builder: (_, __) => const ProfileTabScreen()),
          ]),
        ],
      ),

      // ── Legacy shell routes — redirect into the Universal Shell above.
      // Kept as real routes (not deleted) so every existing
      // `context.go(RouteConstants.farmerX)`/`.shepherdX` call site across
      // the app, and any bookmarked/deep-linked URL, keeps resolving
      // instead of 404ing. Auth/redirect state is validated by _redirect()
      // above BEFORE these run, so an unauthenticated hit still bounces to
      // phone login rather than briefly flashing the target.
      GoRoute(
        path: RouteConstants.farmerDashboard,
        redirect: (_, __) => RouteConstants.home,
      ),
      GoRoute(
        path: RouteConstants.shepherdDashboard,
        redirect: (_, __) => RouteConstants.home,
      ),
      GoRoute(
        path: RouteConstants.farmerLands,
        redirect: (_, __) => RouteConstants.lands,
      ),
      GoRoute(
        path: RouteConstants.shepherdDiscover,
        redirect: (_, __) => RouteConstants.lands,
      ),
      GoRoute(
        path: RouteConstants.farmerBookings,
        redirect: (_, __) => RouteConstants.bookings,
      ),
      GoRoute(
        path: RouteConstants.shepherdBookings,
        redirect: (_, __) => RouteConstants.bookings,
      ),
      GoRoute(
        path: RouteConstants.shepherdVets,
        redirect: (_, __) => RouteConstants.vets,
      ),
      GoRoute(
        path: RouteConstants.farmerProfile,
        redirect: (_, __) => RouteConstants.profile,
      ),
      GoRoute(
        path: RouteConstants.shepherdProfile,
        redirect: (_, __) => RouteConstants.profile,
      ),

      // ── Disease Alerts / advisory (full-screen, no longer a shell tab —
      // reachable from Home's quick actions exactly as before) ────────────
      GoRoute(
        path: RouteConstants.farmerExplore,
        builder: (_, __) => const FarmerExploreScreen(),
      ),

      // ── Farmer land management (full-screen, no bottom nav) ──────────────
      GoRoute(
        path: RouteConstants.farmerAddLand,
        builder: (_, __) => const AddLandScreen(),
      ),
      GoRoute(
        path: RouteConstants.farmerEditLand,
        builder: (_, state) => AddLandScreen(editFarmId: state.pathParameters['landId']),
      ),
      GoRoute(
        path: RouteConstants.farmerLandDetail,
        builder: (_, state) => LandDetailScreen(farmId: state.pathParameters['landId']!),
      ),
      GoRoute(
        path: RouteConstants.farmerLandAvailability,
        builder: (_, state) => AvailabilityCalendarScreen(
          farmId: state.pathParameters['landId']!,
        ),
      ),

      // ── Shepherd land detail (full-screen, no bottom nav) ────────────────
      GoRoute(
        path: RouteConstants.shepherdLandDetail,
        builder: (_, state) =>
            ShepherdLandDetailScreen(farmId: state.pathParameters['landId']!),
      ),

      // ── Vet detail ────────────────────────────────────────────────────────
      GoRoute(
        path: RouteConstants.shepherdVetDetail,
        builder: (_, state) =>
            VetDetailScreen(vetId: state.pathParameters['vetId']!),
      ),

      // ── Booking detail (farmer + shepherd) ───────────────────────────────
      GoRoute(
        path: RouteConstants.farmerBookingDetail,
        builder: (_, state) => BookingDetailScreen(
          bookingId: state.pathParameters['bookingId']!,
          role: 'farmer',
        ),
      ),
      GoRoute(
        path: RouteConstants.shepherdBookingDetail,
        builder: (_, state) => BookingDetailScreen(
          bookingId: state.pathParameters['bookingId']!,
          role: 'shepherd',
        ),
      ),

      // ── Book land (shepherd flow) ─────────────────────────────────────────
      GoRoute(
        path: RouteConstants.shepherdBookLand,
        builder: (_, state) =>
            BookLandScreen(farmId: state.pathParameters['farmId']!),
      ),

      // ── Shared ────────────────────────────────────────────────────────────
      GoRoute(path: RouteConstants.emergency, builder: (_, __) => const EmergencyScreen()),
      GoRoute(path: RouteConstants.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: RouteConstants.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: RouteConstants.assistant, builder: (_, __) => const AssistantScreen()),
      GoRoute(
        path: RouteConstants.reportAlert,
        builder: (_, __) => const ReportAlertScreen(),
      ),
      GoRoute(
        path: RouteConstants.mapPicker,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MapPickerScreen(
            initialLat: extra?['lat'] as double?,
            initialLng: extra?['lng'] as double?,
          );
        },
      ),
      GoRoute(
        path: RouteConstants.shepherdExploreMap,
        builder: (_, __) => const ExploreMapScreen(),
      ),
      GoRoute(
        path: RouteConstants.unifiedSearch,
        builder: (_, __) => const UnifiedSearchScreen(),
      ),
      GoRoute(
        path: RouteConstants.myReportedAlerts,
        builder: (_, __) => const MyReportedAlertsScreen(),
      ),
      GoRoute(
        path: RouteConstants.alertDetailPath,
        builder: (_, state) =>
            AlertDetailScreen(alertId: state.pathParameters['alertId']!),
      ),
      GoRoute(
        path: RouteConstants.alertMap,
        builder: (_, __) => const AlertMapScreen(),
      ),
    ],
  );
});
