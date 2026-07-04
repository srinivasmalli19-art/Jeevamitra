import 'dart:math' as math;

/// Manual geohash implementation — no external package needed.
/// Stores geohash on Firestore docs; range queries use neighboring cells.
class GeoHashHelper {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode lat/lng to geohash string of given precision (chars).
  static String encode(double lat, double lng, {int precision = 7}) {
    double minLat = -90, maxLat = 90, minLng = -180, maxLng = 180;
    final buffer = StringBuffer();
    int bits = 0, bitsTotal = 0, hashValue = 0;

    while (buffer.length < precision) {
      if (bitsTotal.isEven) {
        final mid = (minLng + maxLng) / 2;
        if (lng >= mid) { hashValue = (hashValue << 1) + 1; minLng = mid; }
        else { hashValue = hashValue << 1; maxLng = mid; }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) { hashValue = (hashValue << 1) + 1; minLat = mid; }
        else { hashValue = hashValue << 1; maxLat = mid; }
      }
      bits++;
      bitsTotal++;
      if (bits == 5) {
        buffer.write(_base32[hashValue]);
        bits = 0;
        hashValue = 0;
      }
    }
    return buffer.toString();
  }

  /// Decode geohash to center lat/lng.
  static (double lat, double lng) decode(String hash) {
    double minLat = -90, maxLat = 90, minLng = -180, maxLng = 180;
    bool isLng = true;

    for (final char in hash.split('')) {
      final charIndex = _base32.indexOf(char);
      for (int bits = 4; bits >= 0; bits--) {
        final bitN = (charIndex >> bits) & 1;
        if (isLng) {
          final mid = (minLng + maxLng) / 2;
          if (bitN == 1) { minLng = mid; } else { maxLng = mid; }
        } else {
          final mid = (minLat + maxLat) / 2;
          if (bitN == 1) { minLat = mid; } else { maxLat = mid; }
        }
        isLng = !isLng;
      }
    }
    return ((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  }

  /// Returns [lower, upper] range bounds for a geohash prefix query.
  /// Use: .where('geohash', isGreaterThanOrEqualTo: lower)
  ///      .where('geohash', isLessThanOrEqualTo: upper)
  static (String lower, String upper) queryRange(double lat, double lng, {int precision = 5}) {
    final hash = encode(lat, lng, precision: precision);
    return (hash, _nextHash(hash));
  }

  /// Next base32 string after [hash] in lexicographic order, carrying the
  /// increment through preceding characters (e.g. "...z" -> "...z" + 1 in the
  /// second-to-last place, not a no-op clamp). Used as the inclusive upper
  /// bound of a geohash prefix range query.
  static String _nextHash(String hash) {
    final chars = hash.split('');
    for (int i = chars.length - 1; i >= 0; i--) {
      final idx = _base32.indexOf(chars[i]);
      if (idx < _base32.length - 1) {
        chars[i] = _base32[idx + 1];
        return chars.join();
      }
      chars[i] = _base32[0];
    }
    // Every character was already the maximum symbol — this hash is already
    // the largest possible value of this length, so it is its own upper bound.
    return hash;
  }

  /// Haversine distance in km between two coordinates.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
