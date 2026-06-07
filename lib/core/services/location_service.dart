import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double lat;
  final double lng;
  final double? accuracy;
  const LocationResult({required this.lat, required this.lng, this.accuracy});
}

class LocationService {
  /// Returns current device position after requesting permission.
  /// Throws [LocationException] if denied or unavailable.
  Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Open app settings to grant access.');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LocationResult(lat: pos.latitude, lng: pos.longitude, accuracy: pos.accuracy);
  }

  /// Returns last known position (fast, less accurate) — good for initial map center.
  Future<LocationResult?> getLastKnown() async {
    final pos = await Geolocator.getLastKnownPosition();
    if (pos == null) return null;
    return LocationResult(lat: pos.latitude, lng: pos.longitude);
  }

  double distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // km
  }
}
