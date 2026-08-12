import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/image_upload_service.dart';

enum PhotoStatus { queued, uploading, failed, ready }

/// One land photo, at any point in its lifecycle: freshly picked and
/// waiting its turn, actively uploading, failed (retryable), or a ready
/// photo — either just-uploaded or loaded from an existing farm's
/// `imageUrls`. [localId] is stable for the item's lifetime and used as
/// the widget key that drives reordering.
class PhotoItem {
  final String localId;
  final PhotoStatus status;
  final String? url;
  final Uint8List? previewBytes;
  final double progress;
  final String? storagePath;
  final Object? error;

  const PhotoItem({
    required this.localId,
    required this.status,
    this.url,
    this.previewBytes,
    this.progress = 0,
    this.storagePath,
    this.error,
  });

  PhotoItem copyWith({
    PhotoStatus? status,
    String? url,
    double? progress,
    String? storagePath,
    Object? error,
    bool clearError = false,
  }) =>
      PhotoItem(
        localId: localId,
        status: status ?? this.status,
        url: url ?? this.url,
        previewBytes: previewBytes,
        progress: progress ?? this.progress,
        storagePath: storagePath ?? this.storagePath,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Manages the full lifecycle of a land's photo set: pick (gallery/camera),
/// sequential upload with live progress, retry, cancel, delete, and
/// reorder (which also doubles as "set cover", since the first photo in
/// the list is the cover by convention — no separate schema field).
///
/// Uploads are strictly sequential: a new pick is appended to the queue
/// and [_processQueue] only ever has one upload in flight at a time,
/// matching the "sequential, not parallel" requirement for mobile
/// networks.
class PhotoUploadController extends StateNotifier<List<PhotoItem>> {
  PhotoUploadController({
    required this.ownerId,
    required this.farmId,
    ImageUploadService? imageUploadService,
  })  : _service = imageUploadService ?? ImageUploadService(),
        super(const []);

  static const maxPhotos = 10;

  final String ownerId;
  final String farmId;
  final ImageUploadService _service;
  final _uuid = const Uuid();
  final _files = <String, XFile>{};
  final _handles = <String, UploadHandle>{};
  bool _processing = false;
  bool _disposed = false;

  /// Seeds already-uploaded URLs from an existing farm (Edit Land). Call
  /// once, before any picking happens — a no-op if photos are already
  /// present so it can't clobber an in-progress session.
  void loadExisting(List<String> urls) {
    if (state.isNotEmpty || urls.isEmpty) return;
    state = urls
        .map((u) => PhotoItem(localId: u, status: PhotoStatus.ready, url: u))
        .toList();
  }

  bool get isFull => state.length >= maxPhotos;

  bool get isUploading =>
      state.any((p) => p.status == PhotoStatus.uploading || p.status == PhotoStatus.queued);

  /// Final ordered URL list — what gets written to `imageUrls`. Index 0 is
  /// the cover image.
  List<String> get readyUrls => [
        for (final p in state)
          if (p.status == PhotoStatus.ready && p.url != null) p.url!,
      ];

  Future<void> pickFromGallery() async {
    if (isFull) return;
    final files = await _service.pickMultipleImages(maxImages: maxPhotos - state.length);
    for (final f in files) {
      await _enqueue(f);
    }
    unawaited(_processQueue());
  }

  Future<void> pickFromCamera() async {
    if (isFull) return;
    final file = await _service.pickImage(source: ImageSource.camera);
    if (file != null) {
      await _enqueue(file);
      unawaited(_processQueue());
    }
  }

  Future<void> _enqueue(XFile file) async {
    final localId = _uuid.v4();
    _files[localId] = file;
    final bytes = await file.readAsBytes();
    if (_disposed) return;
    state = [
      ...state,
      PhotoItem(localId: localId, status: PhotoStatus.queued, previewBytes: bytes),
    ];
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      while (!_disposed) {
        PhotoItem? next;
        for (final p in state) {
          if (p.status == PhotoStatus.queued) {
            next = p;
            break;
          }
        }
        if (next == null) break;
        await _uploadItem(next);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _uploadItem(PhotoItem item) async {
    final file = _files[item.localId];
    if (file == null) {
      _setItem(item.localId, (p) => p.copyWith(status: PhotoStatus.failed, error: 'File unavailable'));
      return;
    }
    _setItem(item.localId, (p) => p.copyWith(status: PhotoStatus.uploading, progress: 0));

    StreamSubscription<double>? sub;
    try {
      final fileName = item.storagePath?.split('/').last;
      final handle = await _service.startUpload(
        file: file,
        ownerId: ownerId,
        farmId: farmId,
        fileName: fileName,
      );
      _handles[item.localId] = handle;
      sub = handle.progressStream.listen((p) {
        _setItem(item.localId, (cur) => cur.copyWith(progress: p));
      });
      final url = await handle.downloadUrl;
      _handles.remove(item.localId);
      if (_disposed) return;
      _setItem(
        item.localId,
        (p) => p.copyWith(
          status: PhotoStatus.ready,
          url: url,
          storagePath: handle.storagePath,
          progress: 1,
        ),
      );
    } catch (e) {
      _handles.remove(item.localId);
      // If the item was removed (user cancelled) while this was in
      // flight, don't resurrect it as a visible failure.
      if (_disposed || !state.any((p) => p.localId == item.localId)) return;
      _setItem(item.localId, (p) => p.copyWith(status: PhotoStatus.failed, error: e));
    } finally {
      await sub?.cancel();
    }
  }

  void _setItem(String localId, PhotoItem Function(PhotoItem) update) {
    if (_disposed) return;
    state = [
      for (final p in state)
        if (p.localId == localId) update(p) else p,
    ];
  }

  Future<void> retry(String localId) async {
    final exists = state.any((p) => p.localId == localId && p.status == PhotoStatus.failed);
    if (!exists) return;
    _setItem(localId, (p) => p.copyWith(status: PhotoStatus.queued, clearError: true));
    unawaited(_processQueue());
  }

  /// Cancels an in-flight upload, or simply drops a queued/failed item —
  /// either way the item disappears from the grid.
  Future<void> cancelOrRemove(String localId) async {
    final handle = _handles.remove(localId);
    if (handle != null) {
      await handle.cancel();
    }
    _files.remove(localId);
    if (_disposed) return;
    state = state.where((p) => p.localId != localId).toList();
  }

  /// Deletes an already-uploaded photo (fresh or pre-existing) from
  /// Storage and removes it from the list.
  Future<void> deleteReady(String localId) async {
    final item = state.where((p) => p.localId == localId).firstOrNull;
    if (item?.url != null) {
      await _service.deleteByUrl(item!.url!);
    }
    if (_disposed) return;
    state = state.where((p) => p.localId != localId).toList();
  }

  /// [newIndex] is the final, post-removal index (matches
  /// `ReorderableListView.onReorderItem`'s contract) — callers should not
  /// pre-adjust it for the item having been removed from [oldIndex].
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    final list = List<PhotoItem>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex.clamp(0, list.length), item);
    state = list;
  }

  void setCover(int index) => reorder(index, 0);

  @override
  void dispose() {
    _disposed = true;
    for (final handle in _handles.values) {
      handle.cancel();
    }
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final photoUploadControllerProvider = StateNotifierProvider.autoDispose
    .family<PhotoUploadController, List<PhotoItem>, ({String ownerId, String farmId})>(
  (ref, params) => PhotoUploadController(ownerId: params.ownerId, farmId: params.farmId),
);
