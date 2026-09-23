import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/interaction_message_entity.dart';

class InteractionMessageModel extends InteractionMessageEntity {
  const InteractionMessageModel({
    required super.id,
    required super.senderId,
    required super.senderRole,
    required super.type,
    super.text,
    super.attachmentUrl,
    super.attachmentPath,
    super.attachmentSizeBytes,
    required super.createdAt,
    super.readAt,
  });

  factory InteractionMessageModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return InteractionMessageModel(
      id: doc.id,
      senderId: d['senderId'] as String,
      senderRole: d['senderRole'] as String? ?? '',
      type: d['type'] as String? ?? 'text',
      text: d['text'] as String?,
      attachmentUrl: d['attachmentUrl'] as String?,
      attachmentPath: d['attachmentPath'] as String?,
      attachmentSizeBytes: (d['attachmentSizeBytes'] as num?)?.toInt(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      readAt: d['readAt'] != null ? (d['readAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'senderRole': senderRole,
        'type': type,
        if (text != null) 'text': text,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        if (attachmentPath != null) 'attachmentPath': attachmentPath,
        if (attachmentSizeBytes != null)
          'attachmentSizeBytes': attachmentSizeBytes,
        'createdAt': Timestamp.fromDate(createdAt),
        if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
      };

  InteractionMessageModel copyWithModel({
    DateTime? readAt,
  }) =>
      InteractionMessageModel(
        id: id,
        senderId: senderId,
        senderRole: senderRole,
        type: type,
        text: text,
        attachmentUrl: attachmentUrl,
        attachmentPath: attachmentPath,
        attachmentSizeBytes: attachmentSizeBytes,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );
}
