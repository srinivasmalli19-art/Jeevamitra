class InteractionEntity {
  final String id;
  final String requesterId;
  final String requesterRole; // 'farmer' | 'shepherd' | 'vet'
  final String recipientId;
  final String recipientRole; // 'farmer' | 'shepherd' | 'vet'
  final String interactionType; // e.g. 'vet_consultation' | 'land_inquiry'
  final String contextType; // e.g. 'vet' | 'land'
  final String contextId;
  final String subject;
  final String status; // pending|accepted|active|declined|cancelled|completed
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? lastMessageAt;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final int unreadCountRequester;
  final int unreadCountRecipient;

  const InteractionEntity({
    required this.id,
    required this.requesterId,
    required this.requesterRole,
    required this.recipientId,
    required this.recipientRole,
    required this.interactionType,
    required this.contextType,
    required this.contextId,
    required this.subject,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.unreadCountRequester = 0,
    this.unreadCountRecipient = 0,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isActive => status == 'active';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  // Open: a live thread that blocks a new request for the same
  // requester+context pair (see InteractionLockEntity).
  bool get isOpen => isPending || isAccepted || isActive;

  // Terminal: this pair's lock is free for a new request to be created.
  bool get isTerminal => isDeclined || isCancelled || isCompleted;

  // Messaging is only allowed once the vet/recipient has accepted.
  bool get canMessage => isAccepted || isActive;
}
