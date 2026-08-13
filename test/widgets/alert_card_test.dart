import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/disease_alert_model.dart';
import 'package:jeevamitra/presentation/widgets/explore/alert_card.dart';

import '../helpers/pump_app.dart';

DiseaseAlertModel _alert({
  String severity = 'critical',
  String village = 'Narasaraopet',
  String affectedSpecies = 'sheep',
}) {
  const lat = 16.3067, lng = 80.4365;
  return DiseaseAlertModel(
    id: 'alert-1',
    title: 'FMD Outbreak',
    description: 'desc',
    disease: 'Foot & Mouth Disease',
    affectedSpecies: affectedSpecies,
    severity: severity,
    village: village,
    district: 'Guntur',
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    radiusKm: 50,
    sourceAuthority: 'AH Dept',
    issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

void main() {
  group('AlertCard', () {
    testWidgets('shows title, disease, village/district, distance, species, and severity label',
        (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: AlertCard(alert: _alert(), distanceKm: 2.1, onReadMore: () {}),
          ),
        ),
      );

      expect(find.text('FMD Outbreak'), findsOneWidget);
      expect(find.text('Foot & Mouth Disease'), findsOneWidget);
      expect(find.text('Narasaraopet, Guntur'), findsOneWidget);
      expect(find.text('2.1 km away'), findsOneWidget);
      expect(find.text('Sheep'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Read More'), findsOneWidget);
    });

    testWidgets('falls back to district only when village is blank', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(
            body: AlertCard(alert: _alert(village: ''), onReadMore: () {}),
          ),
        ),
      );
      expect(find.text('Guntur'), findsOneWidget);
      expect(find.textContaining(', Guntur'), findsNothing);
    });

    testWidgets('omits the distance chip when distanceKm is null', (tester) async {
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(body: AlertCard(alert: _alert(), onReadMore: () {})),
        ),
      );
      expect(find.textContaining('km away'), findsNothing);
      expect(find.textContaining('m away'), findsNothing);
    });

    testWidgets('fires onReadMore when the card or Read More button is tapped', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        localizedTestApp(
          Scaffold(body: AlertCard(alert: _alert(), onReadMore: () => tapped++)),
        ),
      );
      await tester.tap(find.text('Read More'));
      expect(tapped, 1);
    });

    testWidgets('shows severity-appropriate label for each severity', (tester) async {
      for (final entry in {
        'critical': 'Critical',
        'high': 'High',
        'medium': 'Medium',
        'low': 'Low',
      }.entries) {
        await tester.pumpWidget(
          localizedTestApp(
            Scaffold(body: AlertCard(alert: _alert(severity: entry.key), onReadMore: () {})),
          ),
        );
        expect(find.text(entry.value), findsOneWidget, reason: 'severity: ${entry.key}');
      }
    });
  });
}
