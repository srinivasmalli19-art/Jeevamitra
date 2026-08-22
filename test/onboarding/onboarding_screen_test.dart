// Regression test for the onboarding flow fix: "Get Started" (the primary
// CTA on the last Welcome page) must go through Choose Profile, not skip
// straight to Phone Login — matching the required flow:
// Welcome -> Choose Profile -> Phone Login -> OTP -> Profile Setup -> Dashboard.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jeevamitra/core/constants/route_constants.dart';
import 'package:jeevamitra/generated/l10n/app_localizations.dart';
import 'package:jeevamitra/presentation/screens/onboarding/onboarding_screen.dart';

Future<void> _pump(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: RouteConstants.onboarding,
    routes: [
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.chooseProfile,
        builder: (_, __) => const Scaffold(body: Text('CHOOSE_PROFILE_SCREEN')),
      ),
      GoRoute(
        path: RouteConstants.phoneLogin,
        builder: (_, __) => const Scaffold(body: Text('PHONE_LOGIN_SCREEN')),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
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
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('"Get Started" on the last page navigates to Choose Profile, '
        'not Phone Login', (tester) async {
      await _pump(tester);

      // Advance through the 3-page carousel to reach "Get Started".
      await tester.tap(find.text('Next →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next →'));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('CHOOSE_PROFILE_SCREEN'), findsOneWidget);
      expect(find.text('PHONE_LOGIN_SCREEN'), findsNothing);
    });

    testWidgets('"Skip" (on an earlier page) still navigates to Choose Profile',
        (tester) async {
      await _pump(tester);

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('CHOOSE_PROFILE_SCREEN'), findsOneWidget);
    });
  });
}
