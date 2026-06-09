import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ImageUploadService {
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Pick one image from gallery or camera.
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) {
    return _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1280,
      maxHeight: 1280,
    );
  }

  /// Pick up to [maxImages] images from gallery.
  Future<List<XFile>> pickMultipleImages({int maxImages = 5}) {
    return _picker.pickMultiImage(
      imageQuality: 75,
      maxWidth: 1280,
      maxHeight: 1280,
      limit: maxImages,
    );
  }

  /// Upload a single XFile and return its download URL.
  /// Uses putData(bytes) so it works on both web and native.
  Future<String> uploadImage({
    required XFile file,
    required String folder,
    String? ownerId,
  }) async {
    final id = _uuid.v4();
    // On web the path is a blob URL; derive extension from the name instead.
    final name = file.name.isNotEmpty ? file.name : file.path;
    final ext = name.contains('.') ? name.split('.').last.split('?').first : 'jpg';
    final storagePath = ownerId != null
        ? '$folder/$ownerId/$id.$ext'
        : '$folder/$id.$ext';

    final bytes = await file.readAsBytes();
    final ref = _storage.ref(storagePath);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  /// Upload multiple files and return list of download URLs.
  Future<List<String>> uploadImages({
    required List<XFile> files,
    required String folder,
    String? ownerId,
    void Function(int done, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final url =
          await uploadImage(file: files[i], folder: folder, ownerId: ownerId);
      urls.add(url);
      onProgress?.call(i + 1, files.length);
    }
    return urls;
  }

  /// Delete an image by its download URL.
  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
