import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/presentation/providers/farm/photo_upload_controller.dart';
import 'package:jeevamitra/presentation/widgets/common/land_photo_manager.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  group('LandPhotoManager', () {
    testWidgets('shows the photo count, a Cover badge on the first photo, and an Add tile',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const params = (ownerId: 'owner-1', farmId: 'farm-1');
      container
          .read(photoUploadControllerProvider(params).notifier)
          .loadExisting(['https://example.com/a.jpg', 'https://example.com/b.jpg']);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: LandPhotoManager(ownerId: 'owner-1', farmId: 'farm-1'),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Photos (2/10)'), findsOneWidget);
        expect(find.text('Cover'), findsOneWidget);
        expect(find.text('First photo is the cover'), findsOneWidget);
        expect(find.byIcon(Icons.add_photo_alternate_rounded), findsOneWidget);
      });
    });

    testWidgets('hides the Add tile once maxPhotos is reached', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const params = (ownerId: 'owner-1', farmId: 'farm-2');
      container.read(photoUploadControllerProvider(params).notifier).loadExisting(
            List.generate(PhotoUploadController.maxPhotos, (i) => 'https://example.com/$i.jpg'),
          );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: LandPhotoManager(ownerId: 'owner-1', farmId: 'farm-2'),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Photos (10/10)'), findsOneWidget);
        expect(find.byIcon(Icons.add_photo_alternate_rounded), findsNothing);
      });
    });

    testWidgets('shows nothing but the header when there are no photos yet', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: LandPhotoManager(ownerId: 'owner-1', farmId: 'farm-3'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Photos (0/10)'), findsOneWidget);
      expect(find.text('First photo is the cover'), findsNothing);
      expect(find.byIcon(Icons.add_photo_alternate_rounded), findsOneWidget);
    });
  });
}
