import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/presentation/providers/connectivity/connectivity_provider.dart';
import 'package:jeevamitra/presentation/widgets/common/offline_banner.dart';

Future<void> _pump(WidgetTester tester, bool isOnline) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [isOnlineProvider.overrideWithValue(isOnline)],
      child: const MaterialApp(
        home: OfflineBanner(child: Scaffold(body: Text('App content'))),
      ),
    ),
  );
}

void main() {
  group('OfflineBanner', () {
    testWidgets('hides the banner and shows child content when online', (tester) async {
      await _pump(tester, true);
      expect(find.text('No internet connection. Some features may be unavailable.'), findsNothing);
      expect(find.text('App content'), findsOneWidget);
    });

    testWidgets('shows the banner when offline, child content still visible', (tester) async {
      await _pump(tester, false);
      await tester.pump(const Duration(milliseconds: 350)); // let AnimatedSize settle
      expect(find.text('No internet connection. Some features may be unavailable.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('App content'), findsOneWidget);
    });

    testWidgets('banner disappears again when connectivity is restored', (tester) async {
      final container = ProviderContainer(
        overrides: [isOnlineProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OfflineBanner(child: Scaffold(body: Text('App content'))),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('No internet connection. Some features may be unavailable.'), findsOneWidget);

      container.updateOverrides([isOnlineProvider.overrideWithValue(true)]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('No internet connection. Some features may be unavailable.'), findsNothing);
    });
  });
}
