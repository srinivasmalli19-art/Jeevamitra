import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/services/image_upload_service.dart';
import 'package:jeevamitra/presentation/providers/farm/photo_upload_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockImageUploadService extends Mock implements ImageUploadService {}

void main() {
  group('PhotoUploadController', () {
    late _MockImageUploadService mockUpload;
    late PhotoUploadController controller;

    setUp(() {
      mockUpload = _MockImageUploadService();
      when(() => mockUpload.deleteByUrl(any())).thenAnswer((_) async {});
      controller = PhotoUploadController(
        ownerId: 'owner-1',
        farmId: 'farm-1',
        imageUploadService: mockUpload,
      );
    });

    tearDown(() => controller.dispose());

    group('loadExisting', () {
      test('seeds ready items from an existing farm\'s imageUrls, in order', () {
        controller.loadExisting(['https://a', 'https://b', 'https://c']);

        expect(controller.state, hasLength(3));
        expect(controller.state.every((p) => p.status == PhotoStatus.ready), isTrue);
        expect(controller.readyUrls, ['https://a', 'https://b', 'https://c']);
      });

      test('is a no-op if items are already present (never clobbers an in-progress session)', () {
        controller.loadExisting(['https://a']);
        controller.loadExisting(['https://x', 'https://y']);

        expect(controller.readyUrls, ['https://a']);
      });

      test('empty list leaves state empty', () {
        controller.loadExisting([]);
        expect(controller.state, isEmpty);
      });
    });

    group('isFull', () {
      test('true once maxPhotos items are present', () {
        controller.loadExisting(List.generate(PhotoUploadController.maxPhotos, (i) => 'url$i'));
        expect(controller.isFull, isTrue);
      });

      test('false below maxPhotos', () {
        controller.loadExisting(['https://a']);
        expect(controller.isFull, isFalse);
      });
    });

    group('reorder / setCover', () {
      test('reorder moves an item to the target position', () {
        controller.loadExisting(['https://a', 'https://b', 'https://c']);

        controller.reorder(2, 0); // move 'c' to the front

        expect(controller.readyUrls, ['https://c', 'https://a', 'https://b']);
      });

      test('setCover moves the tapped photo to index 0 (the cover slot)', () {
        controller.loadExisting(['https://a', 'https://b', 'https://c']);

        controller.setCover(2);

        expect(controller.readyUrls.first, 'https://c');
      });

      test('setCover on the already-first photo is a no-op', () {
        controller.loadExisting(['https://a', 'https://b']);

        controller.setCover(0);

        expect(controller.readyUrls, ['https://a', 'https://b']);
      });

      test('out-of-range oldIndex is ignored rather than throwing', () {
        controller.loadExisting(['https://a']);
        expect(() => controller.reorder(5, 0), returnsNormally);
        expect(controller.readyUrls, ['https://a']);
      });
    });

    group('deleteReady', () {
      test('removes the photo from state and deletes it by URL in Storage', () async {
        controller.loadExisting(['https://a', 'https://b']);
        final target = controller.state.first;

        await controller.deleteReady(target.localId);

        expect(controller.readyUrls, ['https://b']);
        verify(() => mockUpload.deleteByUrl('https://a')).called(1);
      });

      test('deleting an unknown localId is a safe no-op', () async {
        controller.loadExisting(['https://a']);
        await controller.deleteReady('does-not-exist');
        expect(controller.readyUrls, ['https://a']);
        verifyNever(() => mockUpload.deleteByUrl(any()));
      });
    });

    group('cancelOrRemove', () {
      test('removes an item with no in-flight upload without touching Storage', () async {
        controller.loadExisting(['https://a']);
        final target = controller.state.first;

        await controller.cancelOrRemove(target.localId);

        expect(controller.state, isEmpty);
        verifyNever(() => mockUpload.deleteByUrl(any()));
      });
    });
  });
}
