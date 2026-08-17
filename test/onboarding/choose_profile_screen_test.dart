import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/domain/entities/user_profile_type.dart';
import 'package:jeevamitra/presentation/screens/onboarding/choose_profile_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  group('ChooseProfileScreen', () {
    testWidgets('Continue is disabled until a profile is selected', (tester) async {
      await pumpWithProviders(
        tester,
        ChooseProfileScreen(onContinue: (_, __, ___) async {}),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('selecting Livestock Owner enables Continue and reports it', (tester) async {
      UserProfileType? reported;
      await pumpWithProviders(
        tester,
        ChooseProfileScreen(
          onContinue: (_, __, selected) async => reported = selected,
        ),
      );

      await tester.tap(find.text('Livestock Owner'));
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(reported, UserProfileType.livestockOwner);
    });

    testWidgets('selecting Fodder Land Provider reports it', (tester) async {
      UserProfileType? reported;
      await pumpWithProviders(
        tester,
        ChooseProfileScreen(
          onContinue: (_, __, selected) async => reported = selected,
        ),
      );

      await tester.tap(find.text('Fodder Land Provider'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(reported, UserProfileType.fodderLandProvider);
    });

    testWidgets('selecting Both reports it', (tester) async {
      UserProfileType? reported;
      await pumpWithProviders(
        tester,
        ChooseProfileScreen(
          onContinue: (_, __, selected) async => reported = selected,
        ),
      );

      await tester.tap(find.text('Both'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(reported, UserProfileType.both);
    });

    testWidgets('shows the "personalizes, does not limit" notice', (tester) async {
      await pumpWithProviders(
        tester,
        ChooseProfileScreen(onContinue: (_, __, ___) async {}),
      );
      expect(
        find.textContaining('does not limit what you can do'),
        findsOneWidget,
      );
    });
  });
}
