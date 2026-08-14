// Pure-logic coverage for canWithdrawAlert() — the gate that decides
// whether AlertDetailScreen shows its Withdraw/Deactivate action. Actual
// authorization is enforced server-side by firestore.rules regardless;
// this only covers the UI-visibility condition.
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';
import 'package:jeevamitra/data/models/disease_alert_model.dart';
import 'package:jeevamitra/presentation/screens/shared/alerts/alert_detail_screen.dart';

DiseaseAlertModel _alert({
  required bool isActive,
  String reportedBy = 'reporter-1',
}) {
  const lat = 16.3067, lng = 80.4365;
  return DiseaseAlertModel(
    id: 'alert-1',
    title: 'PPR outbreak',
    description: 'desc',
    disease: 'PPR',
    affectedSpecies: 'sheep',
    severity: 'high',
    district: 'Guntur',
    state: 'Andhra Pradesh',
    lat: lat,
    lng: lng,
    geohash: GeoHashHelper.encode(lat, lng),
    radiusKm: 50,
    sourceAuthority: 'AH Dept',
    isActive: isActive,
    issuedAt: DateTime(2026, 1, 1),
    reportedBy: reportedBy,
  );
}

void main() {
  group('canWithdrawAlert', () {
    test('active reporter viewing their own alert -> true', () {
      final alert = _alert(isActive: true, reportedBy: 'reporter-1');
      expect(canWithdrawAlert(alert, 'reporter-1'), isTrue);
    });

    test('a different signed-in user -> false (non-reporter cannot withdraw)', () {
      final alert = _alert(isActive: true, reportedBy: 'reporter-1');
      expect(canWithdrawAlert(alert, 'someone-else'), isFalse);
    });

    test('an already-inactive alert -> false, even for the reporter', () {
      final alert = _alert(isActive: false, reportedBy: 'reporter-1');
      expect(canWithdrawAlert(alert, 'reporter-1'), isFalse);
    });

    test('no signed-in user (null uid) -> false', () {
      final alert = _alert(isActive: true, reportedBy: 'reporter-1');
      expect(canWithdrawAlert(alert, null), isFalse);
    });

    test('an alert with no reportedBy on record -> false for everyone', () {
      final alert = _alert(isActive: true, reportedBy: '');
      expect(canWithdrawAlert(alert, ''), isFalse);
    });
  });
}
