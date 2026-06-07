import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ImageUploadService {
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Pick one image from gallery or camera.
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Pick up to [maxImages] images from gallery.
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 75,
      maxWidth: 1280,
      maxHeight: 1280,
      limit: maxImages,
    );
    return picked.map((x) => File(x.path)).toList();
  }

  /// Upload a single file and return its download URL.
  Future<String> uploadImage({
    required File file,
    required String folder, // e.g. 'farms', 'profiles'
    String? ownerId,
  }) async {
    final id = _uuid.v4();
    final ext = file.path.split('.').last;
    final path = ownerId != null
        ? '$folder/$ownerId/$id.$ext'
        : '$folder/$id.$ext';

    final ref = _storage.ref(path);
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  /// Upload multiple files and return list of download URLs.
  Future<List<String>> uploadImages({
    required List<File> files,
    required String folder,
    String? ownerId,
    void Function(int done, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final url = await uploadImage(file: files[i], folder: folder, ownerId: ownerId);
      urls.add(url);
      onProgress?.call(i + 1, files.length);
    }
    return urls;
  }

  /// Delete an image by its download URL.
  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // File may already be deleted — ignore
    }
  }
}
