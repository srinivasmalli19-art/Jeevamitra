import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresses land-photo bytes to a mobile-network-friendly size before
/// upload: resized to at most 1920px on the long edge, targeting a
/// 300–700KB output by stepping quality down until the target is hit or a
/// quality floor is reached.
class ImageCompressionService {
  static const int _maxDimension = 1920;
  static const int _targetMaxBytes = 700 * 1024;
  static const int _targetMinBytes = 300 * 1024;
  static const List<int> _qualitySteps = [85, 70, 55, 40];

  /// Returns compressed JPEG bytes, or the original [bytes] unchanged if
  /// compression isn't supported on this platform or fails for any reason
  /// — a land photo that uploads uncompressed is far better than an upload
  /// that fails outright.
  Future<Uint8List> compress(Uint8List bytes) async {
    try {
      Uint8List? best;
      for (final quality in _qualitySteps) {
        final result = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: _maxDimension,
          minHeight: _maxDimension,
          quality: quality,
          format: CompressFormat.jpeg,
          keepExif: false,
        );
        best = result;
        if (result.lengthInBytes <= _targetMaxBytes) break;
      }
      final chosen = best ?? bytes;
      // Never return something larger than the original — a tiny source
      // image re-encoded at quality 85 can occasionally grow slightly.
      return chosen.lengthInBytes < bytes.lengthInBytes ? chosen : bytes;
    } catch (e) {
      debugPrint('[ImageCompression] compression failed, using original: $e');
      return bytes;
    }
  }

  /// Exposed for diagnostics/tests — true once bytes are within the
  /// 300–700KB target band (best-effort; small/simple source photos may
  /// legitimately compress below 300KB, which is fine).
  bool isWithinTarget(Uint8List bytes) =>
      bytes.lengthInBytes <= _targetMaxBytes;

  int get targetMinBytes => _targetMinBytes;
  int get targetMaxBytes => _targetMaxBytes;
}
