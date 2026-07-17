import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/geo_hash_helper.dart';

void main() {
  group('GeoHashHelper.encode / decode', () {
    test('encoding then decoding returns approximately the original coordinates', () {
      const lat = 16.3067, lng = 80.4365; // Guntur, AP
      final hash = GeoHashHelper.encode(lat, lng, precision: 9);
      final (decodedLat, decodedLng) = GeoHashHelper.decode(hash);

      expect(decodedLat, closeTo(lat, 0.001));
      expect(decodedLng, closeTo(lng, 0.001));
    });

    test('higher precision produces a longer hash', () {
      expect(GeoHashHelper.encode(16.3, 80.4, precision: 5), hasLength(5));
      expect(GeoHashHelper.encode(16.3, 80.4, precision: 9), hasLength(9));
    });

    test('nearby coordinates share a common hash prefix', () {
      final a = GeoHashHelper.encode(16.3067, 80.4365, precision: 7);
      final b = GeoHashHelper.encode(16.3070, 80.4368, precision: 7);
      expect(a.substring(0, 5), b.substring(0, 5));
    });
  });

  group('GeoHashHelper.queryRange', () {
    test('lower bound equals the encoded hash and upper bound sorts after it', () {
      final (lower, upper) = GeoHashHelper.queryRange(16.3067, 80.4365, precision: 5);
      expect(lower, GeoHashHelper.encode(16.3067, 80.4365, precision: 5));
      expect(upper.compareTo(lower), greaterThan(0));
    });

    test('an all-max-symbol hash ("zzz") is its own upper bound, per the documented fallback',
        () {
      // (90, 180) is the absolute lat/lng corner — every bit resolves to 1,
      // so encode() returns "zzz": already the largest possible value at
      // this precision. _nextHash carries through all three positions,
      // finds no room to increment, and correctly falls back to returning
      // the hash unchanged (see the _nextHash doc comment). A different,
      // non-boundary coordinate exercising a genuine increment is already
      // covered by the "upper bound sorts after" case above.
      final (lower, upper) = GeoHashHelper.queryRange(90.0, 180.0, precision: 3);
      expect(lower, 'zzz');
      expect(upper, 'zzz');
    });
  });

  group('GeoHashHelper.distanceKm', () {
    test('distance to self is zero', () {
      expect(GeoHashHelper.distanceKm(16.3, 80.4, 16.3, 80.4), closeTo(0, 0.0001));
    });

    test('Guntur to Hyderabad is roughly 245km (known real-world distance)', () {
      final d = GeoHashHelper.distanceKm(16.3067, 80.4365, 17.3850, 78.4867);
      expect(d, closeTo(245, 20));
    });

    test('distance is symmetric', () {
      final d1 = GeoHashHelper.distanceKm(16.3067, 80.4365, 17.3850, 78.4867);
      final d2 = GeoHashHelper.distanceKm(17.3850, 78.4867, 16.3067, 80.4365);
      expect(d1, closeTo(d2, 0.0001));
    });
  });
}
