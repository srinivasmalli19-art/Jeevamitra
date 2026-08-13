import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/presentation/widgets/explore/vet_avatar.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  group('VetAvatar', () {
    testWidgets('shows the initial letter when there is no profile image URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VetAvatar(profileImageUrl: null, name: 'Dr. Lakshmi', radius: 32)),
        ),
      );
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('shows "V" for an empty name with no profile image URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VetAvatar(profileImageUrl: null, name: '', radius: 32)),
        ),
      );
      expect(find.text('V'), findsOneWidget);
    });

    testWidgets('hides the initial letter once a profile image URL loads successfully',
        (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: VetAvatar(
                profileImageUrl: 'https://example.com/vet.jpg',
                name: 'Dr. Lakshmi',
                radius: 32,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('D'), findsNothing);
      });
    });
  });
}
