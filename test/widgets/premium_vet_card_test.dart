import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/vet_model.dart';
import 'package:jeevamitra/presentation/widgets/explore/premium_vet_card.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../helpers/pump_app.dart';

VetModel _vet({
  bool isAvailable24x7 = false,
  double rating = 4.5,
  int yearsOfExperience = 8,
  List<String> languages = const ['Telugu', 'Hindi'],
  String specialization = 'Large Animal Medicine',
  String? profileImageUrl,
}) {
  const lat = 16.3067, lng = 80.4365;
  return VetModel(
    id: 'vet-1',
    name: 'Dr. Lakshmi',
    qualification: 'BVSc & AH',
    specialization: specialization,
    phone: '9876543210',
    village: 'Narasaraopet',
    district: 'Guntur',
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    isAvailable24x7: isAvailable24x7,
    rating: rating,
    reviewCount: 42,
    yearsOfExperience: yearsOfExperience,
    languages: languages,
    profileImageUrl: profileImageUrl,
  );
}

void main() {
  group('PremiumVetCard', () {
    testWidgets('shows name, rating, experience, village/district, distance, specialization',
        (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          localizedTestApp(
            Scaffold(
              body: PremiumVetCard(vet: _vet(), distanceKm: 2.1, onViewProfile: () {}),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Dr. Lakshmi'), findsOneWidget);
        expect(find.text('4.5 (42)'), findsOneWidget);
        expect(find.text('8 yrs exp'), findsOneWidget);
        expect(find.text('Narasaraopet, Guntur'), findsOneWidget);
        expect(find.text('2.1 km away'), findsOneWidget);
        expect(find.text('Large Animal Medicine'), findsOneWidget);
        expect(find.text('Telugu'), findsOneWidget);
        expect(find.text('Hindi'), findsOneWidget);
        expect(find.text('Call'), findsOneWidget);
        expect(find.text('Navigate'), findsOneWidget);
        expect(find.text('Book'), findsOneWidget);
        expect(find.text('View Profile'), findsOneWidget);
      });
    });

    testWidgets('shows Available Today badge only when isAvailable24x7 is true', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: PremiumVetCard(
                vet: _vet(isAvailable24x7: true), distanceKm: 1.0, onViewProfile: () {}),
          ),
        ),
      );
      expect(find.text('Available Today'), findsOneWidget);
    });

    testWidgets('hides Available Today badge when not available 24x7', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: PremiumVetCard(
                vet: _vet(isAvailable24x7: false), distanceKm: 1.0, onViewProfile: () {}),
          ),
        ),
      );
      expect(find.text('Available Today'), findsNothing);
    });

    testWidgets('fires onViewProfile when the card or View Profile button is tapped',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: PremiumVetCard(vet: _vet(), distanceKm: 1.0, onViewProfile: () => tapped++),
          ),
        ),
      );
      await tester.tap(find.text('View Profile'));
      expect(tapped, 1);
    });

    testWidgets('never renders raw latitude/longitude as text', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: PremiumVetCard(vet: _vet(), distanceKm: 1.0, onViewProfile: () {}),
          ),
        ),
      );
      expect(find.textContaining('16.3067'), findsNothing);
      expect(find.textContaining('80.4365'), findsNothing);
    });

    testWidgets('shows a fallback initial avatar when there is no profile image, no overflow',
        (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: PremiumVetCard(
                vet: _vet(profileImageUrl: null), distanceKm: 1.0, onViewProfile: () {}),
          ),
        ),
      );
      expect(find.text('D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
