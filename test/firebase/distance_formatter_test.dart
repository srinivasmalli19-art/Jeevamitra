import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/distance_formatter.dart';
import 'package:jeevamitra/generated/l10n/app_localizations_en.dart';

void main() {
  final loc = AppLocalizationsEn();

  group('formatDistanceAway', () {
    test('formats sub-kilometer distances in meters', () {
      expect(formatDistanceAway(0.85, loc), '850 m away');
      expect(formatDistanceAway(0.001, loc), '1 m away');
    });

    test('formats kilometer-plus distances with one decimal', () {
      expect(formatDistanceAway(2.1, loc), '2.1 km away');
      expect(formatDistanceAway(15.0, loc), '15.0 km away');
    });

    test('never contains raw coordinate-looking output', () {
      final msg = formatDistanceAway(3.456, loc);
      expect(msg, isNot(contains(',')));
    });
  });
}
