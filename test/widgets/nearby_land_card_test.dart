import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/farm_model.dart';
import 'package:jeevamitra/presentation/widgets/explore/nearby_land_card.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../helpers/pump_app.dart';

FarmModel _farm({bool isAvailable = true, List<String> imageUrls = const []}) {
  const lat = 16.3067, lng = 80.4365;
  return FarmModel(
    id: 'farm-1',
    ownerId: 'owner-1',
    ownerName: 'Farmer Ravi',
    title: 'Green Pasture',
    description: 'desc',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    village: 'Narasaraopet',
    district: 'Guntur',
    state: 'Andhra Pradesh',
    areaSqMeters: 4046.856 * 3.5,
    areaUnit: 'acre',
    fodderTypes: const [],
    pricePerDayPerAnimal: 25,
    maxAnimals: 100,
    isAvailable: isAvailable,
    imageUrls: imageUrls,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('NearbyLandCard', () {
    testWidgets('shows title, village/district, acres, price, and distance', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          localizedTestApp(
            Scaffold(
              body: NearbyLandCard(
                farm: _farm(imageUrls: const ['https://example.com/a.jpg']),
                distanceKm: 2.1,
                onViewDetails: () {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Green Pasture'), findsOneWidget);
        expect(find.text('Narasaraopet, Guntur'), findsOneWidget);
        expect(find.text('3.5 Acres'), findsOneWidget);
        expect(find.text('2.1 km away'), findsOneWidget);
        expect(find.text('Available'), findsOneWidget);
        expect(find.text('View Details'), findsOneWidget);
        expect(find.text('Navigate'), findsOneWidget);
      });
    });

    testWidgets('shows Not Available badge for an unavailable farm', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: NearbyLandCard(
              farm: _farm(isAvailable: false),
              distanceKm: 0.5,
              onViewDetails: () {},
            ),
          ),
        ),
      );
      expect(find.text('Not Available'), findsOneWidget);
      expect(find.text('500 m away'), findsOneWidget);
    });

    testWidgets('fires onViewDetails when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: NearbyLandCard(
              farm: _farm(),
              distanceKm: 1.0,
              onViewDetails: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('View Details'));
      expect(tapped, isTrue);
    });

    testWidgets('never renders raw latitude/longitude as text', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: NearbyLandCard(farm: _farm(), distanceKm: 1.0, onViewDetails: () {}),
          ),
        ),
      );
      expect(find.textContaining('16.3067'), findsNothing);
      expect(find.textContaining('80.4365'), findsNothing);
    });

    testWidgets('shows a placeholder icon when there are no images, no overflow', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: NearbyLandCard(farm: _farm(imageUrls: const []), distanceKm: 1.0, onViewDetails: () {}),
          ),
        ),
      );
      // landscape_rounded appears twice by design: once as the no-image
      // placeholder, once as the acres-row icon.
      expect(find.byIcon(Icons.landscape_rounded), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
