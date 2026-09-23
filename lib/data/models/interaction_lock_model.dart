import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/interaction_lock_entity.dart';

class InteractionLockModel extends InteractionLockEntity {
  const InteractionLockModel({
    required super.id,
    required super.requesterId,
    required super.contextId,
    required super.recipientId,
    required super.status,
    required super.currentInteractionId,
    required super.updatedAt,
  });

  static String buildId({required String requesterId, required String contextId}) =>
      '${requesterId}_$contextId';

  factory InteractionLockModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return InteractionLockModel(
      id: doc.id,
      requesterId: d['requesterId'] as String,
      contextId: d['contextId'] as String,
      recipientId: d['recipientId'] as String,
      status: d['status'] as String? ?? 'pending',
      currentInteractionId: d['currentInteractionId'] as String,
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'requesterId': requesterId,
        'contextId': contextId,
        'recipientId': recipientId,
        'status': status,
        'currentInteractionId': currentInteractionId,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  InteractionLockModel copyWithModel({
    String? status,
    String? currentInteractionId,
    DateTime? updatedAt,
  }) =>
      InteractionLockModel(
        id: id,
        requesterId: requesterId,
        contextId: contextId,
        recipientId: recipientId,
        status: status ?? this.status,
        currentInteractionId: currentInteractionId ?? this.currentInteractionId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
