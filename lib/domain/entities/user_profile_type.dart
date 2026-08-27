/// The three user-facing identity profiles introduced by the Profile
/// Restructure: purely a personalization concept ("who the user is / how
/// they want the app tailored"), never a permission — every profile has
/// identical feature access. Maps onto the existing, unchanged backend
/// `role` field ('farmer' | 'shepherd') for storage/query/security
/// compatibility; the profile choice itself (including the "both" case a
/// single `role` string can't represent) is preserved separately in
/// `UserDoc.profileType` for personalization only.
enum UserProfileType {
  /// 🐄 Primarily interested in livestock care and finding/booking land.
  livestockOwner,

  /// 🌾 Primarily provides grazing/fodder land and manages listings.
  fodderLandProvider,

  /// 🔄 Both provides land and books land.
  both;

  /// The existing backend role this profile is stored/queried as. `both`
  /// has no dedicated backend value (the schema is intentionally not being
  /// migrated to a third role) — it defaults to `'farmer'`, an arbitrary
  /// but documented choice; it does not restrict what a "both" user can do,
  /// since role is never used as a permission check.
  String get backendRole => switch (this) {
        UserProfileType.livestockOwner => 'shepherd',
        UserProfileType.fodderLandProvider => 'farmer',
        UserProfileType.both => 'farmer',
      };

  /// The Firestore-stored value for `UserDoc.profileType`.
  String get storageValue => name;

  /// Emoji used consistently everywhere this profile is displayed (Choose
  /// Profile onboarding, Change Profile in the Profile screen, etc).
  String get emoji => switch (this) {
        UserProfileType.livestockOwner => '🐄',
        UserProfileType.fodderLandProvider => '🌾',
        UserProfileType.both => '🔄',
      };

  static UserProfileType? fromStorageValue(String? value) => switch (value) {
        'livestockOwner' => UserProfileType.livestockOwner,
        'fodderLandProvider' => UserProfileType.fodderLandProvider,
        'both' => UserProfileType.both,
        _ => null,
      };

  /// Best-effort profile for a user who predates this feature and has no
  /// stored `profileType` — inferred from their existing `role` so legacy
  /// farmer/shepherd accounts still get a sensible personalization default
  /// without any migration.
  static UserProfileType inferFromRole(String role) =>
      role == 'shepherd' ? UserProfileType.livestockOwner : UserProfileType.fodderLandProvider;
}
