import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/models/notification_model.dart';
import 'package:jeevamitra/data/repositories/notification_repository.dart';

NotificationModel _notif({
  String id = '',
  String userId = 'user-1',
  bool isRead = false,
  DateTime? createdAt,
}) {
  return NotificationModel(
    id: id,
    userId: userId,
    type: 'booking_confirmed',
    title: 'Booking confirmed!',
    body: 'Your booking has been confirmed.',
    payload: const {'bookingId': 'b1'},
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2026, 7, 1),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late NotificationRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = NotificationRepository(firestore: firestore);
  });

  group('watchNotifications', () {
    test('only returns notifications for the given user, newest first', () async {
      await repo.createNotification(_notif(userId: 'user-1', createdAt: DateTime(2026, 7, 1)));
      await repo.createNotification(_notif(userId: 'user-1', createdAt: DateTime(2026, 7, 3)));
      await repo.createNotification(_notif(userId: 'user-2', createdAt: DateTime(2026, 7, 2)));

      final results = await repo.watchNotifications('user-1').first;

      expect(results, hasLength(2));
      expect(results.every((n) => n.userId == 'user-1'), isTrue);
      expect(results.first.createdAt.isAfter(results.last.createdAt), isTrue);
    });
  });

  group('markAsRead / markAllAsRead', () {
    test('markAsRead flips a single notification', () async {
      final ref = await firestore.collection('notifications').add(_notif().toFirestore());
      await repo.markAsRead(ref.id);
      final doc = await firestore.collection('notifications').doc(ref.id).get();
      expect(doc.data()!['isRead'], isTrue);
    });

    test('markAllAsRead flips every unread notification for that user only', () async {
      await firestore.collection('notifications').add(_notif(userId: 'user-1', isRead: false).toFirestore());
      await firestore.collection('notifications').add(_notif(userId: 'user-1', isRead: false).toFirestore());
      await firestore.collection('notifications').add(_notif(userId: 'user-1', isRead: true).toFirestore());
      await firestore.collection('notifications').add(_notif(userId: 'user-2', isRead: false).toFirestore());

      await repo.markAllAsRead('user-1');

      final user1 = await firestore.collection('notifications').where('userId', isEqualTo: 'user-1').get();
      expect(user1.docs.every((d) => d.data()['isRead'] == true), isTrue);

      final user2 = await firestore.collection('notifications').where('userId', isEqualTo: 'user-2').get();
      expect(user2.docs.first.data()['isRead'], isFalse);
    });
  });

  group('deleteNotification', () {
    test('removes the document', () async {
      final ref = await firestore.collection('notifications').add(_notif().toFirestore());
      await repo.deleteNotification(ref.id);
      final doc = await firestore.collection('notifications').doc(ref.id).get();
      expect(doc.exists, isFalse);
    });
  });
}
