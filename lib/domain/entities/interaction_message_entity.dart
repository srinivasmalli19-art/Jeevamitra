class InteractionMessageEntity {
  final String id;
  final String senderId;
  final String senderRole; // 'farmer' | 'shepherd' | 'vet'
  final String type; // 'text' | 'image' | 'system'
  final String? text;
  final String? attachmentUrl;
  final String? attachmentPath;
  final int? attachmentSizeBytes;
  final DateTime createdAt;
  final DateTime? readAt;

  const InteractionMessageEntity({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.type,
    this.text,
    this.attachmentUrl,
    this.attachmentPath,
    this.attachmentSizeBytes,
    required this.createdAt,
    this.readAt,
  });

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isSystem => type == 'system';
  bool get isRead => readAt != null;
}
