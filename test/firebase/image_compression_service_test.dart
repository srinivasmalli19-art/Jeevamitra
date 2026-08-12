import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/services/image_compression_service.dart';

void main() {
  group('ImageCompressionService', () {
    late ImageCompressionService service;

    setUp(() {
      service = ImageCompressionService();
    });

    test('falls back to the original bytes when the native compressor is unavailable',
        () async {
      // flutter_test's VM environment has no real platform-channel
      // implementation for flutter_image_compress, so compress() must hit
      // its catch-and-fall-back path — exactly the resilience the "a land
      // photo that uploads uncompressed beats one that fails outright"
      // design decision is meant to guarantee. This proves that guarantee
      // holds rather than just asserting a mocked return value.
      final original = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      final result = await service.compress(original);
      expect(result, original);
    });

    test('isWithinTarget is true at or under the 700KB ceiling', () {
      final small = Uint8List(300 * 1024);
      final atCeiling = Uint8List(700 * 1024);
      final tooBig = Uint8List(701 * 1024);

      expect(service.isWithinTarget(small), isTrue);
      expect(service.isWithinTarget(atCeiling), isTrue);
      expect(service.isWithinTarget(tooBig), isFalse);
    });

    test('exposes the documented 300-700KB target band', () {
      expect(service.targetMinBytes, 300 * 1024);
      expect(service.targetMaxBytes, 700 * 1024);
    });
  });
}
