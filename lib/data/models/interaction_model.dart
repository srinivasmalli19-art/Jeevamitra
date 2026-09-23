import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/interaction_entity.dart';

class InteractionModel extends InteractionEntity {
  const InteractionModel({
    required super.id,
    required super.requesterId,
    required super.requesterRole,
    required super.recipientId,
    required super.recipientRole,
    required super.interactionType,
    required super.contextType,
    required super.contextId,
    required super.subject,
    required super.status,
    required super.createdAt,
    super.acceptedAt,
    super.completedAt,
    super.lastMessageAt,
    super.lastMessageText,
    super.lastMessageSenderId,
    super.unreadCountRequester,
    super.unreadCountRecipient,
  });

  factory InteractionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return InteractionModel(
      id: doc.id,
      requesterId: d['requesterId'] as String,
      requesterRole: d['requesterRole'] as String? ?? '',
      recipientId: d['recipientId'] as String,
      recipientRole: d['recipientRole'] as String? ?? '',
      interactionType: d['interactionType'] as String? ?? '',
      contextType: d['contextType'] as String? ?? '',
      contextId: d['contextId'] as String? ?? '',
      subject: d['subject'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      acceptedAt: d['acceptedAt'] != null
          ? (d['acceptedAt'] as Timestamp).toDate()
          : null,
      completedAt: d['completedAt'] != null
          ? (d['completedAt'] as Timestamp).toDate()
          : null,
      lastMessageAt: d['lastMessageAt'] != null
          ? (d['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessageText: d['lastMessageText'] as String?,
      lastMessageSenderId: d['lastMessageSenderId'] as String?,
      unreadCountRequester: (d['unreadCountRequester'] as num?)?.toInt() ?? 0,
      unreadCountRecipient: (d['unreadCountRecipient'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'requesterId': requesterId,
        'requesterRole': requesterRole,
        'recipientId': recipientId,
        'recipientRole': recipientRole,
        'interactionType': interactionType,
        'contextType': contextType,
        'contextId': contextId,
        'subject': subject,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
        if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
        if (lastMessageAt != null) 'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
        if (lastMessageText != null) 'lastMessageText': lastMessageText,
        if (lastMessageSenderId != null) 'lastMessageSenderId': lastMessageSenderId,
        'unreadCountRequester': unreadCountRequester,
        'unreadCountRecipient': unreadCountRecipient,
      };

  InteractionModel copyWithModel({
    String? status,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? lastMessageAt,
    String? lastMessageText,
    String? lastMessageSenderId,
    int? unreadCountRequester,
    int? unreadCountRecipient,
  }) =>
      InteractionModel(
        id: id,
        requesterId: requesterId,
        requesterRole: requesterRole,
        recipientId: recipientId,
        recipientRole: recipientRole,
        interactionType: interactionType,
        contextType: contextType,
        contextId: contextId,
        subject: subject,
        status: status ?? this.status,
        createdAt: createdAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        completedAt: completedAt ?? this.completedAt,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessageText: lastMessageText ?? this.lastMessageText,
        lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
        unreadCountRequester: unreadCountRequester ?? this.unreadCountRequester,
        unreadCountRecipient: unreadCountRecipient ?? this.unreadCountRecipient,
      );
}
