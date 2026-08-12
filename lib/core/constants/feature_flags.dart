/// Centralised on/off switches for capabilities that are fully built and
/// production-ready but intentionally not exposed to users yet — flip a
/// flag here rather than deleting or commenting out working code.
class FeatureFlags {
  /// Firebase Storage (and therefore land photo management — pick, upload,
  /// reorder, cover, delete) is off for the v1.0 release. This is a
  /// product decision, not a bug workaround: the project stays on the
  /// Firebase Spark (free) plan until the app has been validated with
  /// real users, and Spark does not include Storage. Confirmed directly
  /// (not assumed) as of Batch 2A: `curl
  /// https://firebasestorage.googleapis.com/v0/b/jeevamitra.firebasestorage.app/o`
  /// returns 404 — the bucket itself isn't provisioned yet, not just
  /// access-restricted.
  ///
  /// The full feature is built and ready — see
  /// [lib/core/services/image_upload_service.dart],
  /// [lib/core/services/image_compression_service.dart],
  /// [lib/presentation/providers/farm/photo_upload_controller.dart],
  /// [lib/presentation/widgets/common/land_photo_manager.dart],
  /// `storage.rules`, and `FarmModel.imageUrls`.
  ///
  /// To re-enable in a future version:
  ///   1. Console → Storage → Get Started (requires upgrading to the
  ///      Blaze plan first — Storage is not available on Spark at all,
  ///      confirmed above).
  ///   2. Deploy rules: `firebase deploy --only storage:rules` (rules
  ///      already declare the `farms/{ownerId}/{farmId}/{fileName}`
  ///      path this feature writes to).
  ///   3. Set this flag to `true`.
  ///   4. That's it — every call site that touches Storage already checks
  ///      this flag first; no other code changes are required.
  static const bool photoUploadsEnabled = false;
}
