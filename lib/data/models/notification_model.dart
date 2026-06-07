import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    required super.payload,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      type: d['type'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      payload: Map<String, dynamic>.from(d['payload'] as Map? ?? {}),
      isRead: d['isRead'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'payload': payload,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        payload: payload,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
