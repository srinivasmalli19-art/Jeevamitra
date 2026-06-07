import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._();

  final _rc = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval:
          kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 1),
    ));

    await _rc.setDefaults({
      'max_animals_per_booking': 200,
      'min_booking_days': 1,
      'booking_radius_km': 200.0,
      'enable_voice_assistant': true,
      'enable_disease_alerts': true,
      'app_maintenance_mode': false,
      'maintenance_message': '',
    });

    try {
      await _rc.fetchAndActivate();
    } catch (e) {
      debugPrint('[RemoteConfig] fetch error: $e');
    }
  }

  int get maxAnimalsPerBooking => _rc.getInt('max_animals_per_booking');
  int get minBookingDays => _rc.getInt('min_booking_days');
  double get bookingRadiusKm => _rc.getDouble('booking_radius_km');
  bool get enableVoice => _rc.getBool('enable_voice_assistant');
  bool get enableAlerts => _rc.getBool('enable_disease_alerts');
  bool get maintenanceMode => _rc.getBool('app_maintenance_mode');
  String get maintenanceMessage => _rc.getString('maintenance_message');
}
