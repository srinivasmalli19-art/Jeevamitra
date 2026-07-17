import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/presentation/providers/connectivity/connectivity_provider.dart';

void main() {
  group('isOnlineProvider', () {
    test('defaults to true (optimistic) before connectivityProvider has emitted', () {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => const Stream<bool>.empty()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isOnlineProvider), isTrue);
    });

    test('reflects false once connectivityProvider emits offline', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(false)),
        ],
      );
      addTearDown(container.dispose);

      // Subscribe so the StreamProvider actually starts listening.
      container.listen(connectivityProvider, (_, __) {});
      await container.pump();

      expect(container.read(isOnlineProvider), isFalse);
    });

    test('reflects true once connectivityProvider emits online', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(connectivityProvider, (_, __) {});
      await container.pump();

      expect(container.read(isOnlineProvider), isTrue);
    });

    test('stays optimistic (true) if the connectivity stream errors', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.error(Exception('platform channel failure'))),
        ],
      );
      addTearDown(container.dispose);

      container.listen(connectivityProvider, (_, __) {});
      await container.pump();

      expect(container.read(isOnlineProvider), isTrue);
    });
  });
}
