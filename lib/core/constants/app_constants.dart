class AppConstants {
  static const String appName = 'JeevaMitra';
  static const String appVersion = '1.0.0';
  static const String appPackage = 'com.slc.jeevamitra';

  // Phone auth
  static const int otpLength = 6;
  static const int otpTimeoutSeconds = 60;
  static const int phoneMinLength = 10;

  // Pagination
  static const int pageSize = 20;
  static const int nearbyRadiusKm = 50;

  // Cache
  static const int cacheExpiryMinutes = 30;
  static const String hiveBoxUser = 'jm_user';
  static const String hiveBoxSettings = 'jm_settings';
  static const String hiveBoxCache = 'jm_cache';

  // Preferences keys
  static const String prefLanguage = 'lang';
  static const String prefOnboarded = 'onboarded';
  static const String prefFcmToken = 'fcm_token';

  // Supported languages
  static const List<String> supportedLocales = ['te', 'hi', 'en'];
  static const String defaultLocale = 'te';

  // Image limits
  static const int maxImagesPerListing = 5;
  static const int maxImageSizeMb = 5;

  // Booking
  static const int minBookingDays = 1;
  static const int maxBookingDays = 365;

  // Sarvam AI
  static const String sarvamBaseUrl = 'https://api.sarvam.ai';
  static const String sarvamDefaultLanguage = 'te-IN';
}
