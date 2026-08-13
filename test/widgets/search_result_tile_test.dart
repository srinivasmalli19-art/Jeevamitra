import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/generated/l10n/app_localizations_en.dart';
import 'package:jeevamitra/presentation/screens/shared/search/search_result.dart';
import 'package:jeevamitra/presentation/widgets/explore/search_result_tile.dart';

import '../helpers/pump_app.dart';

const _land = SearchResultItem(
  category: SearchResultCategory.land,
  id: 'f1',
  title: 'Green Pasture',
  subtitle: 'Narasaraopet, Guntur',
  distanceKm: 2.1,
);

void main() {
  final loc = AppLocalizationsEn();

  group('SearchResultTile', () {
    testWidgets('shows title, subtitle, distance, and category badge', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(body: SearchResultTile(result: _land, onTap: () {})),
        ),
      );

      expect(find.text('Green Pasture'), findsOneWidget);
      expect(find.text('Narasaraopet, Guntur'), findsOneWidget);
      expect(find.text('2.1 km away'), findsOneWidget);
      expect(find.text('Land'), findsOneWidget);
    });

    testWidgets('formats sub-km distances in meters', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: SearchResultTile(
              result: const SearchResultItem(
                category: SearchResultCategory.vet,
                id: 'v1',
                title: 'Dr. Rao',
                subtitle: 'Guntur',
                distanceKm: 0.35,
              ),
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('350 m away'), findsOneWidget);
      expect(find.text('Vet'), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(body: SearchResultTile(result: _land, onTap: () => tapped++)),
        ),
      );
      await tester.tap(find.byType(SearchResultTile));
      expect(tapped, 1);
    });

    testWidgets('shows the right icon and label for each category', (tester) async {
      for (final category in SearchResultCategory.values) {
        await tester.pumpWidget(
          localizedTestApp(
            Scaffold(
              body: SearchResultTile(
                result: SearchResultItem(
                  category: category,
                  id: 'x',
                  title: 'Title',
                  subtitle: 'Subtitle',
                  distanceKm: 1,
                ),
                onTap: () {},
              ),
            ),
          ),
        );
        expect(find.text(category.labelFor(loc)), findsOneWidget, reason: 'category: $category');
        expect(find.byIcon(category.icon), findsOneWidget, reason: 'category: $category');
      }
    });
  });
}
