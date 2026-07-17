import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/models/notification_model.dart';
import 'package:jeevamitra/data/repositories/notification_repository.dart';
import 'package:jeevamitra/presentation/providers/notifications/notification_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

NotificationModel _notif({String id = 'n1', bool isRead = false}) => NotificationModel(
      id: id,
      userId: 'user-1',
      type: 'booking_confirmed',
      title: 'Booking confirmed!',
      body: 'Your booking is confirmed.',
      payload: const {'bookingId': 'b1'},
      isRead: isRead,
      createdAt: DateTime(2026, 7, 1),
    );

void main() {
  group('NotificationNotifier', () {
    late MockNotificationRepository mockRepo;
    late NotificationNotifier notifier;

    setUp(() {
      mockRepo = MockNotificationRepository();
      notifier = NotificationNotifier(mockRepo);
    });

    test('markAsRead delegates to the repository', () async {
      when(() => mockRepo.markAsRead('n1')).thenAnswer((_) async {});
      await notifier.markAsRead('n1');
      verify(() => mockRepo.markAsRead('n1')).called(1);
      expect(notifier.state.hasError, isFalse);
    });

    test('markAsRead failure is captured as an error state, not thrown', () async {
      when(() => mockRepo.markAsRead('n1')).thenThrow(Exception('offline'));
      await notifier.markAsRead('n1');
      expect(notifier.state.hasError, isTrue);
    });

    test('delete delegates to the repository', () async {
      when(() => mockRepo.deleteNotification('n1')).thenAnswer((_) async {});
      await notifier.delete('n1');
      verify(() => mockRepo.deleteNotification('n1')).called(1);
    });
  });

  group('unreadCountProvider', () {
    test('counts only unread notifications from the current stream state', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => Stream.value([
              _notif(id: 'a', isRead: false),
              _notif(id: 'b', isRead: true),
              _notif(id: 'c', isRead: false),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen(notificationsProvider, (_, __) {});
      await container.pump();

      expect(container.read(unreadCountProvider), 2);
    });

    test('is zero when there are no notifications', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(notificationsProvider, (_, __) {});
      await container.pump();

      expect(container.read(unreadCountProvider), 0);
    });
  });
}
