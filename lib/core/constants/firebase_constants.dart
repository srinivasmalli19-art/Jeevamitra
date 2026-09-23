class FirebaseConstants {
  // Collections
  static const String users = 'users';
  static const String farms = 'farms';
  static const String fodderPlots = 'fodder_plots';
  static const String bookings = 'bookings';
  static const String reviews = 'reviews';
  static const String vets = 'vets';
  static const String diseaseAlerts = 'disease_alerts';
  static const String notifications = 'notifications';
  static const String blockedPeriods = 'blocked_periods';
  static const String conversations = 'conversations';
  static const String messages = 'messages';
  static const String interactions = 'interactions';
  static const String interactionLocks = 'interactionLocks';
  static const String emergencyContacts = 'emergency_contacts';
  static const String analytics = 'analytics';

  // Storage buckets
  static const String storageFarms = 'farms';
  static const String storageProfiles = 'profiles';
  static const String storageVets = 'vets';

  // User roles
  static const String roleFarmer = 'farmer';
  static const String roleShepherd = 'shepherd';
  static const String roleVet = 'vet';

  // Interaction statuses
  static const String interactionPending = 'pending';
  static const String interactionAccepted = 'accepted';
  static const String interactionActive = 'active';
  static const String interactionDeclined = 'declined';
  static const String interactionCancelled = 'cancelled';
  static const String interactionCompleted = 'completed';

  // Booking statuses
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingActive = 'active';
  static const String bookingCompleted = 'completed';
  static const String bookingCancelled = 'cancelled';

  // Alert types
  static const String alertDisease = 'disease';
  static const String alertWeather = 'weather';
  static const String alertMarket = 'market';
}
