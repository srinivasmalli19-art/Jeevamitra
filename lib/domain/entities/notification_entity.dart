abstract class NotificationEntity {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });
}
