class RouteConstants {
  // Onboarding
  static const String splash = '/splash';
  static const String languageSelect = '/onboarding/language';
  static const String onboarding = '/onboarding';
  static const String chooseProfile = '/onboarding/profile';

  // Auth
  static const String phoneLogin = '/auth/phone';
  static const String otpVerification = '/auth/otp';
  static const String roleSelect = '/auth/role';
  static const String profileSetup = '/auth/setup';

  // Farmer shell
  static const String farmerDashboard = '/farmer/dashboard';
  static const String farmerLands = '/farmer/lands';
  static const String farmerLandDetail = '/farmer/lands/:landId';
  static const String farmerAddLand = '/farmer/lands/add';
  static const String farmerEditLand = '/farmer/lands/:landId/edit';
  static const String farmerLandAvailability = '/farmer/lands/:landId/availability';
  static const String farmerBookings = '/farmer/bookings';
  static const String farmerBookingDetail = '/farmer/bookings/:bookingId';
  static const String farmerExplore = '/farmer/explore';
  static const String farmerProfile = '/farmer/profile';

  // Shepherd shell
  static const String shepherdDashboard = '/shepherd/dashboard';
  static const String shepherdDiscover = '/shepherd/discover';
  static const String shepherdLandDetail = '/shepherd/discover/:landId';
  static const String shepherdBookings = '/shepherd/bookings';
  static const String shepherdBookingDetail = '/shepherd/bookings/:bookingId';
  static const String shepherdBookLand = '/shepherd/book/:farmId';
  static const String shepherdVets = '/shepherd/vets';
  static const String shepherdVetDetail = '/shepherd/vets/:vetId';
  static const String shepherdProfile = '/shepherd/profile';
  static const String shepherdExploreMap = '/shepherd/explore-map';

  // Shared
  static const String emergency = '/shared/emergency';
  static const String assistant = '/shared/assistant';
  static const String notifications = '/shared/notifications';
  static const String settings = '/shared/settings';
  static const String mapPicker = '/shared/map-picker';
  static const String reportAlert = '/shared/report-alert';
  static const String unifiedSearch = '/shared/search';
  static const String alertDetailPath = '/shared/alerts/:alertId';
  static const String alertMap = '/shared/alerts-map';
  static const String myReportedAlerts = '/shared/alerts/mine';

  // Helper: path with substituted params
  static String landDetail(String landId) => '/farmer/lands/$landId';
  static String farmerEditLandPath(String landId) => '/farmer/lands/$landId/edit';
  static String farmerLandAvailabilityPath(String landId) => '/farmer/lands/$landId/availability';
  static String bookingDetail(String role, String bookingId) =>
      '/$role/bookings/$bookingId';
  static String vetDetail(String vetId) => '/shepherd/vets/$vetId';
  static String shepherdLand(String landId) => '/shepherd/discover/$landId';
  static String shepherdBook(String farmId) => '/shepherd/book/$farmId';
  static String alertDetail(String alertId) => '/shared/alerts/$alertId';
}
