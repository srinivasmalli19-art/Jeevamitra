import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/presentation/widgets/common/dashboard_stat_card.dart';
import 'package:jeevamitra/presentation/widgets/common/hero_banner.dart';
import 'package:jeevamitra/presentation/widgets/common/responsive_center.dart';
import 'package:jeevamitra/presentation/widgets/common/standard_app_bar.dart';

void main() {
  group('HeroBanner', () {
    testWidgets('renders greeting, name, and subtitle with no overflow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 150,
              child: HeroBanner(
                greeting: 'Good morning',
                name: 'Ramesh Kumar',
                subtitle: 'Anantapur',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Anantapur'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with only name (no greeting/subtitle) and no overflow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 150,
              child: HeroBanner(name: 'Hello, Ramesh!'),
            ),
          ),
        ),
      );
      expect(find.text('Hello, Ramesh!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow with a very long name on a narrow width',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 150,
              width: 200,
              child: HeroBanner(
                name: 'Hello, Venkata Narasimha Rao Chowdary!',
                subtitle: 'A very long village and district name here',
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'does not overflow with a long name, subtitle icon, and trailing '
        'action icons on a narrow width (matches the dashboard header)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 150,
              width: 320,
              child: HeroBanner(
                name: 'Hello, Venkata Narasimha Rao Chowdary!',
                subtitle: 'Anantapur District, Andhra Pradesh',
                subtitleIcon: Icons.location_on_rounded,
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.mic_rounded, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Badge(
                      label: Text('9+'),
                      child: Icon(Icons.notifications_outlined,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('StandardAppBar', () {
    testWidgets('renders title and preferred size includes bottom height',
        (tester) async {
      const bar = StandardAppBar(
        title: 'My Lands',
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: SizedBox.shrink(),
        ),
      );
      expect(bar.preferredSize.height, 56 + 48);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: StandardAppBar(title: 'My Lands'),
            body: SizedBox.shrink(),
          ),
        ),
      );
      expect(find.text('My Lands'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a custom leading widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: StandardAppBar(
              title: 'Add Land',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {},
              ),
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });

  group('DashboardStatCard', () {
    testWidgets('renders value and label, fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: DashboardStatCard(
                    label: 'My Lands',
                    value: '3',
                    icon: Icons.landscape_rounded,
                    color: Colors.green,
                    onTap: () => tapped = true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('My Lands'), findsOneWidget);

      await tester.tap(find.byType(DashboardStatCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('shows a badge dot when badge is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: DashboardStatCard(
                    label: 'Pending',
                    value: '2',
                    icon: Icons.hourglass_top_rounded,
                    color: Colors.orange,
                    badge: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow with a long value/label on a narrow card',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 90,
              child: DashboardStatCard(
                label: 'Total Earnings This Season',
                value: '₹1,23,45,678',
                icon: Icons.currency_rupee_rounded,
                color: Colors.brown,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'sizes to a fixed width inside a Wrap (the narrow-phone 2x2 '
        'overview layout) without needing a Flex ancestor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 146,
                    child: DashboardStatCard(
                      label: 'My Lands',
                      value: '3',
                      icon: Icons.landscape_rounded,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(
                    width: 146,
                    child: DashboardStatCard(
                      label: 'Earnings',
                      value: '₹12.3K',
                      icon: Icons.currency_rupee_rounded,
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('₹12.3K'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ResponsiveCenter', () {
    testWidgets('stays full width on a phone-sized viewport', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCenter(
              maxWidth: 720,
              child: SizedBox(height: 10, child: Placeholder()),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps to maxWidth on a wide (tablet/web) viewport',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCenter(
              maxWidth: 720,
              child: SizedBox(height: 10, width: double.infinity),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(SizedBox).last);
      expect(size.width, 720);
    });
  });
}
