import '../constants/geo_constants.dart';

enum AreaUnit { squareMeters, acres, hectares, guntha, cents }

class AreaCalculator {
  static double convert(double value, AreaUnit from, AreaUnit to) {
    final sqMeters = _toSqMeters(value, from);
    return _fromSqMeters(sqMeters, to);
  }

  static double _toSqMeters(double value, AreaUnit unit) {
    switch (unit) {
      case AreaUnit.squareMeters: return value;
      case AreaUnit.acres: return value * GeoConstants.acreToSqMeters;
      case AreaUnit.hectares: return value * GeoConstants.hectareToSqMeters;
      case AreaUnit.guntha: return value * GeoConstants.gunthToSqMeters;
      case AreaUnit.cents: return value * GeoConstants.centToSqMeters;
    }
  }

  static double _fromSqMeters(double sqMeters, AreaUnit unit) {
    switch (unit) {
      case AreaUnit.squareMeters: return sqMeters;
      case AreaUnit.acres: return sqMeters / GeoConstants.acreToSqMeters;
      case AreaUnit.hectares: return sqMeters / GeoConstants.hectareToSqMeters;
      case AreaUnit.guntha: return sqMeters / GeoConstants.gunthToSqMeters;
      case AreaUnit.cents: return sqMeters / GeoConstants.centToSqMeters;
    }
  }

  static String label(AreaUnit unit) {
    switch (unit) {
      case AreaUnit.squareMeters: return 'm²';
      case AreaUnit.acres: return 'Acres';
      case AreaUnit.hectares: return 'Hectares';
      case AreaUnit.guntha: return 'Guntha';
      case AreaUnit.cents: return 'Cents';
    }
  }

  /// Estimate fodder capacity: ~2 sheep per acre per month for good pasture.
  static int estimateSheepCapacity(double acres) => (acres * 2).floor();
}
