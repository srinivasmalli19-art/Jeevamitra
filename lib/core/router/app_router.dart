import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_constants.dart';
import 'firebase_initialized_provider.dart';
import '../../presentation/providers/auth/auth_provider.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/language_select_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/phone_login_screen.dart';
import '../../presentation/screens/auth/otp_verification_screen.dart';
import '../../presentation/screens/auth/role_select_screen.dart';
import '../../presentation/screens/auth/profile_setup_screen.dart';
import '../../presentation/screens/farmer/farmer_shell.dart';
import '../../presentation/screens/farmer/dashboard/farmer_dashboard_screen.dart';
import '../../presentation/screens/farmer/lands/farmer_lands_screen.dart';
import '../../presentation/screens/farmer/lands/add_land_screen.dart';
import '../../presentation/screens/farmer/lands/availability_calendar_screen.dart';
import '../../presentation/screens/farmer/lands/land_detail_screen.dart';
import '../../presentation/screens/farmer/bookings/farmer_bookings_screen.dart';
import '../../presentation/screens/farmer/explore/farmer_explore_screen.dart';
import '../../presentation/screens/farmer/profile/farmer_profile_screen.dart';
import '../../presentation/screens/shepherd/shepherd_shell.dart';
import '../../presentation/screens/shepherd/dashboard/shepherd_dashboard_screen.dart';
import '../../presentation/screens/shepherd/discover/shepherd_discover_screen.dart';
import '../../presentation/screens/shepherd/discover/shepherd_land_detail_screen.dart';
import '../../presentation/screens/shepherd/bookings/shepherd_bookings_screen.dart';
import '../../presentation/screens/shepherd/vets/shepherd_vets_screen.dart';
import '../../presentation/screens/shepherd/vets/vet_detail_screen.dart';
import '../../presentation/screens/shepherd/profile/shepherd_profile_screen.dart';
import '../../presentation/screens/shared/emergency_screen.dart';
import '../../presentation/screens/shared/booking_detail_screen.dart';
import '../../presentation/screens/shared/assistant_screen.dart';
import '../../presentation/screens/shared/notifications_screen.dart';
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

  final firebaseReady = ref.read(firebaseInitializedProvider);
  if (!firebaseReady) return null; // stays on splash showing setup screen

  final authAsync = ref.read(authStateProvider);
  final userDocAsync = ref.read(currentUserDocProvider);

  final isLoading = authAsync.isLoading || userDocAsync.isLoading;
  if (isLoading) return null;

  final user = authAsync.valueOrNull;
  final doc = userDocAsync.valueOrNull;

  final isOnSplash = loc == RouteConstants.splash;
  final isOnOnboarding = loc.startsWith('/onboarding');
  final isOnAuth = loc.startsWith('/auth');
  final isOnFarmer = loc.startsWith('/farmer');
  final isOnShepherd = loc.startsWith('/shepherd');

  // Not logged in
  if (user == null) {
    if (isOnFarmer || isOnShepherd) return RouteConstants.phoneLogin;
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

  // Fully onboarded — redirect away from auth/onboarding screens
  if (isOnAuth || isOnOnboarding || isOnSplash) {
    return doc.isFarmer ? RouteConstants.farmerDashboard : RouteConstants.shepherdDashboard;
  }

  // Farmer trying to access shepherd routes
  if (doc.isFarmer && isOnShepherd) return RouteConstants.farmerDashboard;

  // Shepherd trying to access farmer routes
  if (doc.isShepherd && isOnFarmer) return RouteConstants.shepherdDashboard;

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

      // ── Farmer Shell ──────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => FarmerShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.farmerDashboard, builder: (_, __) => const FarmerDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.farmerLands, builder: (_, __) => const FarmerLandsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.farmerBookings, builder: (_, __) => const FarmerBookingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.farmerExplore, builder: (_, __) => const FarmerExploreScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.farmerProfile, builder: (_, __) => const FarmerProfileScreen()),
          ]),
        ],
      ),

      // ── Shepherd Shell ────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ShepherdShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.shepherdDashboard, builder: (_, __) => const ShepherdDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.shepherdDiscover, builder: (_, __) => const ShepherdDiscoverScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.shepherdBookings, builder: (_, __) => const ShepherdBookingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.shepherdVets, builder: (_, __) => const ShepherdVetsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RouteConstants.shepherdProfile, builder: (_, __) => const ShepherdProfileScreen()),
          ]),
        ],
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
    ],
  );
});
