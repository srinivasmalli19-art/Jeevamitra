// Tracks the current state of one requester+context pair, so a duplicate
// OPEN interaction can be prevented via a single exists()/get() check in
// security rules rather than a query. Document id is always
// "{requesterId}_{contextId}" — see InteractionLockModel.buildId. The
// interaction record itself uses an auto-generated id (InteractionEntity);
// this lock is a separate, durable pointer, never the record of history.
class InteractionLockEntity {
  final String id; // "{requesterId}_{contextId}"
  final String requesterId;
  final String contextId;
  final String recipientId;
  final String status; // mirrors the linked interaction's status
  final String currentInteractionId;
  final DateTime updatedAt;

  const InteractionLockEntity({
    required this.id,
    required this.requesterId,
    required this.contextId,
    required this.recipientId,
    required this.status,
    required this.currentInteractionId,
    required this.updatedAt,
  });

  bool get isOpen => status == 'pending' || status == 'accepted' || status == 'active';
  bool get isTerminal => status == 'declined' || status == 'cancelled' || status == 'completed';
}
