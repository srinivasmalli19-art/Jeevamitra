// LocationService wraps the `geolocator` package, which itself delegates to
// GeolocatorPlatform.instance — the standard seam the plugin exposes for
// tests, swapped here for a fake so no real GPS/platform channel is needed.
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:jeevamitra/core/services/location_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

Position _position({double lat = 16.3067, double lng = 80.4365, double accuracy = 5.0}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime(2026, 7, 1),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  late MockGeolocatorPlatform mockPlatform;
  late LocationService service;

  setUp(() {
    mockPlatform = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockPlatform;
    service = LocationService();
  });

  group('getCurrentLocation', () {
    test('returns lat/lng/accuracy when service enabled and permission granted', () async {
      when(() => mockPlatform.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => mockPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => mockPlatform.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer((_) async => _position());

      final result = await service.getCurrentLocation();

      expect(result.lat, 16.3067);
      expect(result.lng, 80.4365);
      expect(result.accuracy, 5.0);
    });

    test('requests permission when initially denied, and succeeds if then granted', () async {
      when(() => mockPlatform.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => mockPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => mockPlatform.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => mockPlatform.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer((_) async => _position());

      final result = await service.getCurrentLocation();
      expect(result.lat, 16.3067);
      verify(() => mockPlatform.requestPermission()).called(1);
    });

    test('throws when location services are disabled on the device', () async {
      when(() => mockPlatform.isLocationServiceEnabled()).thenAnswer((_) async => false);

      expect(() => service.getCurrentLocation(), throwsA(isA<Exception>()));
    });

    test('throws when permission is denied even after requesting', () async {
      when(() => mockPlatform.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => mockPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => mockPlatform.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      expect(() => service.getCurrentLocation(), throwsA(isA<Exception>()));
    });

    test('throws with a clear message when permission is permanently denied', () async {
      when(() => mockPlatform.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => mockPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);

      expect(
        () => service.getCurrentLocation(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('permanently denied'))),
      );
    });
  });

  group('getLastKnown', () {
    test('returns null when no last-known position exists', () async {
      when(() => mockPlatform.getLastKnownPosition(
            forceLocationManager: any(named: 'forceLocationManager'),
          )).thenAnswer((_) async => null);
      final result = await service.getLastKnown();
      expect(result, isNull);
    });

    test('returns lat/lng when a last-known position exists', () async {
      when(() => mockPlatform.getLastKnownPosition(
            forceLocationManager: any(named: 'forceLocationManager'),
          )).thenAnswer((_) async => _position(lat: 17.0, lng: 79.0));
      final result = await service.getLastKnown();
      expect(result!.lat, 17.0);
      expect(result.lng, 79.0);
    });
  });

  group('distanceBetween', () {
    test('converts the platform\'s meter result to km', () {
      // Geolocator.distanceBetween() also delegates to GeolocatorPlatform,
      // so the platform call itself must be stubbed too.
      when(() => mockPlatform.distanceBetween(any(), any(), any(), any()))
          .thenReturn(245000.0); // meters
      final km = service.distanceBetween(16.3067, 80.4365, 17.3850, 78.4867);
      expect(km, 245.0);
    });
  });
}
