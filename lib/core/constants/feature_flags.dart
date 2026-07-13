/// Centralised on/off switches for capabilities that are fully built and
/// production-ready but intentionally not exposed to users yet — flip a
/// flag here rather than deleting or commenting out working code.
class FeatureFlags {
  /// Firebase Storage (and therefore any feature that uploads a file — land
  /// listing photos today) is off for the v1.0 release. This is a product
  /// decision, not a bug workaround: the project stays on the Firebase
  /// Spark (free) plan until the app has been validated with real users,
  /// and Spark does not include Storage.
  ///
  /// Nothing Storage-related was deleted to ship without it — see
  /// [lib/core/services/image_upload_service.dart], `storage.rules`, and
  /// `FarmModel.imageUrls` — all of it stays as-is, ready to go.
  ///
  /// To re-enable in a future version:
  ///   1. Confirm Firebase Storage is enabled on the Firebase project
  ///      (Console → Storage → Get Started) and `storage.rules` has been
  ///      deployed (`firebase deploy --only storage:rules`).
  ///   2. Set this flag to `true`.
  ///   3. That's it — every call site that touches Storage already checks
  ///      this flag first; no other code changes are required.
  static const bool photoUploadsEnabled = false;
}
