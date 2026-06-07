import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final _col = FirebaseFirestore.instance
      .collection(FirebaseConstants.notifications)
      .withConverter<NotificationModel>(
        fromFirestore: (snap, _) => NotificationModel.fromFirestore(snap),
        toFirestore: (n, _) => n.toFirestore(),
      );

  Stream<List<NotificationModel>> watchNotifications(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Future<void> markAsRead(String notificationId) =>
      _col.doc(notificationId).update({'isRead': true});

  Future<void> markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final unread = await _col
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> createNotification(NotificationModel n) =>
      _col.add(n);

  Future<void> deleteNotification(String notificationId) =>
      _col.doc(notificationId).delete();
}
