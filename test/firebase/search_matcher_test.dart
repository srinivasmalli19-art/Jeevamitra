import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/search_matcher.dart';

void main() {
  group('matchesQuery', () {
    test('empty query matches everything', () {
      expect(matchesQuery('', ['Guntur']), isTrue);
      expect(matchesQuery('   ', ['Guntur']), isTrue);
    });

    test('partial text matches (substring, not exact)', () {
      expect(matchesQuery('gunt', ['Guntur']), isTrue);
      expect(matchesQuery('ntur', ['Guntur']), isTrue);
    });

    test('case-insensitive', () {
      expect(matchesQuery('GUNTUR', ['guntur']), isTrue);
      expect(matchesQuery('guntur', ['GUNTUR']), isTrue);
    });

    test('matches if any field matches', () {
      expect(matchesQuery('rao', ['Green Pasture', 'Dr. Rao', 'Guntur']), isTrue);
    });

    test('false when no field matches', () {
      expect(matchesQuery('xyz', ['Green Pasture', 'Guntur']), isFalse);
    });

    test('null fields are skipped, not a crash', () {
      expect(matchesQuery('guntur', [null, 'Guntur']), isTrue);
      expect(matchesQuery('xyz', [null, null]), isFalse);
    });

    test('leading/trailing whitespace on the query is ignored', () {
      expect(matchesQuery('  guntur  ', ['Guntur']), isTrue);
    });
  });
}
