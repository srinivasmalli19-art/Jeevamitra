class GeoConstants {
  // Geohash precision levels
  // Precision 5 → ~4.9km × 4.9km cell (use for nearby search)
  // Precision 7 → ~152m × 152m cell (use for precise location)
  static const int geohashPrecisionSearch = 5;
  static const int geohashPrecisionStore = 7;

  // Earth radius in km (for Haversine formula)
  static const double earthRadiusKm = 6371.0;

  // Default map center — Andhra Pradesh, India
  static const double defaultLat = 16.5062;
  static const double defaultLng = 80.6480;

  // Zoom levels
  static const double zoomVillage = 14.0;
  static const double zoomDistrict = 10.0;
  static const double zoomState = 7.0;

  // Search radii in km
  static const double radiusNearby = 10.0;
  static const double radiusDistrict = 50.0;
  static const double radiusState = 200.0;

  // Area units
  static const double acreToSqMeters = 4046.856;
  static const double hectareToSqMeters = 10000.0;
  static const double gunthToSqMeters = 101.17;   // 1 guntha (Telugu unit)
  static const double centToSqMeters = 40.468564; // 1 cent
}
