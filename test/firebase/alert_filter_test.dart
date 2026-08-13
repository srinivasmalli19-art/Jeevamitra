import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/disease_alert_model.dart';
import 'package:jeevamitra/presentation/screens/shared/alerts/alert_filter.dart';
import 'package:jeevamitra/presentation/screens/shared/alerts/alert_severity.dart';

DiseaseAlertModel _alert({
  required String id,
  String severity = 'medium',
  String affectedSpecies = 'all',
  String village = 'Narasaraopet',
  String district = 'Guntur',
  DateTime? issuedAt,
}) {
  const lat = 16.3067, lng = 80.4365;
  return DiseaseAlertModel(
    id: id,
    title: 'Alert $id',
    description: 'desc',
    disease: 'PPR',
    affectedSpecies: affectedSpecies,
    severity: severity,
    village: village,
    district: district,
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    radiusKm: 50,
    sourceAuthority: 'AH Dept',
    issuedAt: issuedAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('AlertSeverity', () {
    test('of() maps each known severity to a distinct label', () {
      expect(AlertSeverity.of('critical').label, 'Critical');
      expect(AlertSeverity.of('high').label, 'High');
      expect(AlertSeverity.of('medium').label, 'Medium');
      expect(AlertSeverity.of('low').label, 'Low');
    });

    test('unknown severity falls back to low, not a crash', () {
      expect(AlertSeverity.of('unknown').label, 'Low');
    });

    test('weight orders critical before high before medium before low', () {
      expect(AlertSeverity.weight('critical'), lessThan(AlertSeverity.weight('high')));
      expect(AlertSeverity.weight('high'), lessThan(AlertSeverity.weight('medium')));
      expect(AlertSeverity.weight('medium'), lessThan(AlertSeverity.weight('low')));
    });
  });

  group('AlertFilterState.apply', () {
    test('filters by severity', () {
      final alerts = [_alert(id: 'a', severity: 'critical'), _alert(id: 'b', severity: 'low')];
      const filter = AlertFilterState(severities: {'critical'});
      expect(filter.apply(alerts).map((a) => a.id), ['a']);
    });

    test('filters by species', () {
      final alerts = [_alert(id: 'a', affectedSpecies: 'sheep'), _alert(id: 'b', affectedSpecies: 'cattle')];
      const filter = AlertFilterState(species: {'sheep'});
      expect(filter.apply(alerts).map((a) => a.id), ['a']);
    });

    test('filters by village substring, case-insensitive', () {
      final alerts = [_alert(id: 'a', village: 'Narasaraopet'), _alert(id: 'b', village: 'Guntur City')];
      const filter = AlertFilterState(village: 'narasa');
      expect(filter.apply(alerts).map((a) => a.id), ['a']);
    });

    test('filters by district substring, case-insensitive', () {
      final alerts = [_alert(id: 'a', district: 'Guntur'), _alert(id: 'b', district: 'Krishna')];
      const filter = AlertFilterState(district: 'GUNTUR');
      expect(filter.apply(alerts).map((a) => a.id), ['a']);
    });

    test('filters by issued date range', () {
      final alerts = [
        _alert(id: 'old', issuedAt: DateTime(2025, 1, 1)),
        _alert(id: 'recent', issuedAt: DateTime(2026, 6, 1)),
      ];
      final filter = AlertFilterState(issuedFrom: DateTime(2026, 1, 1));
      expect(filter.apply(alerts).map((a) => a.id), ['recent']);
    });

    test('hasActiveFilters is false for the default state', () {
      expect(const AlertFilterState().hasActiveFilters, isFalse);
    });

    test('hasActiveFilters is true once any filter is set', () {
      expect(const AlertFilterState(severities: {'high'}).hasActiveFilters, isTrue);
      expect(const AlertFilterState(village: 'x').hasActiveFilters, isTrue);
    });

    test('copyWith clearIssuedFrom/clearIssuedTo actually clear', () {
      final withDates = AlertFilterState(issuedFrom: DateTime(2026, 1, 1), issuedTo: DateTime(2026, 6, 1));
      final cleared = withDates.copyWith(clearIssuedFrom: true, clearIssuedTo: true);
      expect(cleared.issuedFrom, isNull);
      expect(cleared.issuedTo, isNull);
    });
  });

  group('sortByRecent', () {
    test('orders most recently issued first', () {
      final alerts = [
        _alert(id: 'old', issuedAt: DateTime(2025, 1, 1)),
        _alert(id: 'new', issuedAt: DateTime(2026, 6, 1)),
      ];
      final sorted = sortByRecent(alerts);
      expect(sorted.map((a) => a.id), ['new', 'old']);
    });
  });

  group('urgentOnly', () {
    test('keeps only critical and high severity, critical first', () {
      final alerts = [
        _alert(id: 'low', severity: 'low'),
        _alert(id: 'high', severity: 'high'),
        _alert(id: 'medium', severity: 'medium'),
        _alert(id: 'critical', severity: 'critical'),
      ];
      final urgent = urgentOnly(alerts);
      expect(urgent.map((a) => a.id), ['critical', 'high']);
    });

    test('empty when nothing is high/critical severity', () {
      final alerts = [_alert(id: 'a', severity: 'low'), _alert(id: 'b', severity: 'medium')];
      expect(urgentOnly(alerts), isEmpty);
    });
  });
}
