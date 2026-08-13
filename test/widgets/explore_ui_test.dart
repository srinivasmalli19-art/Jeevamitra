import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/presentation/widgets/explore/category_card.dart';
import 'package:jeevamitra/presentation/widgets/explore/empty_state_card.dart';
import 'package:jeevamitra/presentation/widgets/explore/explore_header.dart';
import 'package:jeevamitra/presentation/widgets/explore/loading_skeleton.dart';
import 'package:jeevamitra/presentation/widgets/explore/retry_card.dart';
import 'package:jeevamitra/presentation/widgets/explore/search_card.dart';

import '../helpers/pump_app.dart';

void main() {
  group('ExploreHeader', () {
    testWidgets('renders title and subtitle with no overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 150,
              child: ExploreHeader(title: 'Explore', subtitle: 'Alerts & tips'),
            ),
          ),
        ),
      );
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Alerts & tips'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow on a narrow width with a long title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 150,
              width: 200,
              child: ExploreHeader(
                title: 'A Very Long Explore Section Title Indeed',
                subtitle: 'An equally long subtitle describing this section',
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SearchCard', () {
    testWidgets('shows hint text and accepts typed input', (tester) async {
      String? changed;
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: SearchCard(hint: 'Search things...', onChanged: (v) => changed = v),
          ),
        ),
      );
      expect(find.text('Search things...'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ppr vaccine');
      expect(changed, 'ppr vaccine');
    });

    testWidgets('shows a clear button once text is entered, clears on tap', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(const Scaffold(body: SearchCard(hint: 'Search...'))),
      );
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });

  group('CategoryCard', () {
    testWidgets('renders label and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(
              icon: Icons.medical_services_rounded,
              label: 'Health',
              color: Colors.green,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.text('Health'), findsOneWidget);
      await tester.tap(find.byType(CategoryCard));
      expect(tapped, isTrue);
    });

    testWidgets('does not overflow with a long label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryCard(
              icon: Icons.medical_services_rounded,
              label: 'A Very Long Category Label',
              color: Colors.green,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('EmptyStateCard', () {
    testWidgets('renders title, subtitle, and an optional action button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateCard(
              icon: Icons.inbox_rounded,
              title: 'Nothing Here',
              subtitle: 'Come back later.',
              buttonLabel: 'Retry',
              onButtonTap: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.text('Nothing Here'), findsOneWidget);
      expect(find.text('Come back later.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(tapped, isTrue);
    });

    testWidgets('renders without a button when none is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateCard(
              icon: Icons.inbox_rounded,
              title: 'Nothing Here',
              subtitle: 'Come back later.',
            ),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('LoadingSkeleton', () {
    testWidgets('renders count skeleton cards inside a bounded parent without overflow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(height: 200, child: LoadingSkeleton(count: 5)),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('RetryCard', () {
    testWidgets('shows a translated message, never the raw error, and fires onRetry',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: RetryCard(
              error: FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.textContaining('permission-denied'), findsNothing);
      expect(find.text("You don't have permission to do that."), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('hides the retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: RetryCard(error: Exception('boom')),
          ),
        ),
      );
      expect(find.text('Try Again'), findsNothing);
    });
  });
}
