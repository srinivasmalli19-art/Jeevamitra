import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/url_launch_helper.dart';

const _channel = MethodChannel('plugins.flutter.io/url_launcher');

void _mockUrlLauncher({required bool canLaunch, required bool launch}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    switch (call.method) {
      case 'canLaunch':
        return canLaunch;
      case 'launch':
        return launch;
      default:
        return null;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  Future<bool> pumpAndLaunch(WidgetTester tester, {String failureMessage = 'Could not open this link'}) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await launchExternalUrl(
                  context,
                  Uri.parse('https://example.com'),
                  failureMessage: failureMessage,
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return result!;
  }

  group('launchExternalUrl', () {
    testWidgets('returns true and shows no SnackBar when the URL launches successfully',
        (tester) async {
      _mockUrlLauncher(canLaunch: true, launch: true);
      final result = await pumpAndLaunch(tester);
      expect(result, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('returns false and shows the failure SnackBar when canLaunch is false',
        (tester) async {
      _mockUrlLauncher(canLaunch: false, launch: true);
      final result = await pumpAndLaunch(tester, failureMessage: 'No dialer app found');
      expect(result, isFalse);
      expect(find.text('No dialer app found'), findsOneWidget);
    });

    testWidgets('returns false and shows the failure SnackBar when launch itself fails',
        (tester) async {
      _mockUrlLauncher(canLaunch: true, launch: false);
      final result = await pumpAndLaunch(tester, failureMessage: 'Could not open maps');
      expect(result, isFalse);
      expect(find.text('Could not open maps'), findsOneWidget);
    });
  });

  group('URI builders', () {
    test('telUri builds a tel: URI', () {
      expect(telUri('9876543210').toString(), 'tel:9876543210');
    });

    test('whatsappUri builds a wa.me URI with country code, no text', () {
      expect(whatsappUri('98765 43210').toString(), 'https://wa.me/919876543210');
    });

    test('whatsappUri encodes an optional pre-filled message', () {
      final uri = whatsappUri('9876543210', text: 'Hello there');
      expect(uri.toString(), 'https://wa.me/919876543210?text=Hello%20there');
    });

    test('mapsSearchUri builds a Google Maps search URI from coordinates', () {
      final uri = mapsSearchUri(16.3067, 80.4365);
      expect(uri.toString(), 'https://www.google.com/maps/search/?api=1&query=16.3067,80.4365');
    });
  });
}
