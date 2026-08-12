import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'image_compression_service.dart';

/// A single in-flight upload: exposes progress (0.0–1.0), the eventual
/// download URL, and lets the caller cancel the underlying [UploadTask].
class UploadHandle {
  UploadHandle(this._task, this.storagePath) {
    _task.snapshotEvents.listen((snap) {
      if (snap.totalBytes > 0) {
        _progress = snap.bytesTransferred / snap.totalBytes;
      }
    });
  }

  final UploadTask _task;

  /// Full Storage path this upload writes to (e.g.
  /// `farms/{ownerUid}/{farmId}/{fileName}`), kept so a failed/cancelled
  /// upload can be retried at the exact same path.
  final String storagePath;

  double _progress = 0;
  double get progress => _progress;

  /// Live progress updates (0.0–1.0) for callers driving a UI off this
  /// upload — e.g. a StateNotifier re-emitting state on each tick.
  Stream<double> get progressStream => _task.snapshotEvents.map(
        (snap) => snap.totalBytes > 0 ? snap.bytesTransferred / snap.totalBytes : 0.0,
      );

  Future<String> get downloadUrl async {
    final snap = await _task;
    return snap.ref.getDownloadURL();
  }

  Future<void> cancel() => _task.cancel();
}

/// Land-photo pick/compress/upload/delete, scoped to
/// `farms/{ownerUid}/{farmId}/{fileName}` in Firebase Storage.
///
/// Uploads are always sequential from the caller's side (each
/// [uploadImage] call is awaited fully by callers before starting the
/// next) — deliberately not parallelized, to stay gentle on the rural
/// mobile networks this app targets.
class ImageUploadService {
  ImageUploadService({
    FirebaseStorage? storage,
    ImageCompressionService? compressionService,
  })  : _storageOverride = storage,
        _compression = compressionService ?? ImageCompressionService();

  final FirebaseStorage? _storageOverride;
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  final ImageCompressionService _compression;
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  /// Pick one image from gallery or camera. image_picker already resizes
  /// to 1920px / quality 85 at the OS level before bytes ever reach Dart;
  /// [ImageCompressionService] then does the real byte-size-targeted pass.
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) {
    return _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
  }

  /// Pick up to [maxImages] images from the gallery.
  Future<List<XFile>> pickMultipleImages({int maxImages = 10}) {
    return _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
      limit: maxImages,
    );
  }

  String _extensionFor(XFile file) {
    final name = file.name.isNotEmpty ? file.name : file.path;
    return name.contains('.') ? name.split('.').last.split('?').first : 'jpg';
  }

  /// Starts uploading [file] to `farms/{ownerId}/{farmId}/{fileName}` and
  /// returns immediately with a handle for tracking progress/cancellation.
  /// [fileName] lets a retry reuse the exact same path as the failed
  /// attempt instead of leaving an abandoned partial object behind.
  Future<UploadHandle> startUpload({
    required XFile file,
    required String ownerId,
    required String farmId,
    String? fileName,
  }) async {
    final bytes = await file.readAsBytes();
    final compressed = await _compression.compress(bytes);
    final ext = _extensionFor(file);
    final name = fileName ?? '${_uuid.v4()}.$ext';
    final storagePath = 'farms/$ownerId/$farmId/$name';

    final ref = _storage.ref(storagePath);
    final task = ref.putData(compressed, SettableMetadata(contentType: 'image/jpeg'));
    return UploadHandle(task, storagePath);
  }

  /// Convenience one-shot upload (no progress/cancel access) — used where
  /// callers just need the final URL, e.g. tests or simple call sites.
  Future<String> uploadImage({
    required XFile file,
    required String ownerId,
    required String farmId,
  }) async {
    final handle = await startUpload(file: file, ownerId: ownerId, farmId: farmId);
    return handle.downloadUrl;
  }

  /// Re-uploads raw [bytes] to the exact [storagePath] of a previously
  /// failed/cancelled upload.
  Future<UploadHandle> retryUpload({
    required Uint8List bytes,
    required String storagePath,
  }) async {
    final ref = _storage.ref(storagePath);
    final task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return UploadHandle(task, storagePath);
  }

  /// Deletes a single photo by its download URL. Errors are swallowed
  /// deliberately — retrying a delete against a URL that's already gone
  /// (e.g. a double-tap) shouldn't surface as a user-facing failure, since
  /// the end state (file absent) is what the caller wanted either way.
  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }

  /// Deletes every photo under a farm's folder — used when the farm
  /// itself is deleted, so no orphaned Storage objects are left behind.
  /// Best-effort: a failure on one file doesn't stop the rest from being
  /// cleaned up.
  Future<void> deleteFarmFolder({
    required String ownerId,
    required String farmId,
  }) async {
    try {
      final result = await _storage.ref('farms/$ownerId/$farmId').listAll();
      for (final item in result.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }
}
