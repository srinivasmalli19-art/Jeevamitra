import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/interaction_lock_model.dart';
import '../models/interaction_model.dart';

/// Thrown by [InteractionRepository.createInteraction] when a lock already
/// exists for this requester+context pair and its linked interaction is
/// still open (pending/accepted/active). The caller already has a live
/// interaction for this pair; a new one is deliberately not created.
class InteractionAlreadyOpenException implements Exception {
  final String message;
  const InteractionAlreadyOpenException(
      [this.message = 'An open interaction already exists for this request.']);
  @override
  String toString() => message;
}

/// Thrown for arguments that are obviously invalid before any Firestore
/// round-trip is attempted — e.g. a missing id, an empty subject, or a
/// requester targeting themselves. Cheap, local, no network access.
class InvalidInteractionRequestException implements Exception {
  final String message;
  const InvalidInteractionRequestException(this.message);
  @override
  String toString() => message;
}

/// Thrown when Firestore itself rejects the write (`FirebaseException` with
/// code `permission-denied`) — i.e. firestore.rules refused it. This is the
/// authoritative security boundary; see the class-level doc on
/// [InteractionRepository.createInteraction] for which checks are only
/// enforced here rather than pre-validated client-side.
class InteractionPermissionDeniedException implements Exception {
  final String message;
  const InteractionPermissionDeniedException(
      [this.message =
          'This request was rejected by the server. The recipient, role, '
          'or context may not be valid for this interaction.']);
  @override
  String toString() => message;
}

/// Thrown when the transaction fails for a reason other than the two above
/// (network error, emulator/backend error, retries exhausted under
/// contention, etc). Never left partially applied — Firestore transactions
/// are all-or-nothing, so a thrown exception here guarantees neither the
/// interaction nor the lock write was committed.
class InteractionTransactionFailedException implements Exception {
  final String message;
  const InteractionTransactionFailedException(this.message);
  @override
  String toString() => message;
}

/// Data-access layer for the general user-to-user interaction/messaging
/// system (see interaction_entity.dart / interaction_lock_entity.dart).
/// Phase 3 + 4 only: creation, reads, and the atomic duplicate-prevention
/// lock. Sending messages, notifications, and status-transition UI belong to
/// later phases.
class InteractionRepository {
  InteractionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  late final _interactionsCol = _firestore
      .collection(FirebaseConstants.interactions)
      .withConverter<InteractionModel>(
        fromFirestore: (snap, _) => InteractionModel.fromFirestore(snap),
        toFirestore: (i, _) => i.toFirestore(),
      );

  late final _locksCol = _firestore
      .collection(FirebaseConstants.interactionLocks)
      .withConverter<InteractionLockModel>(
        fromFirestore: (snap, _) => InteractionLockModel.fromFirestore(snap),
        toFirestore: (l, _) => l.toFirestore(),
      );

  late final _farmsCol = _firestore.collection(FirebaseConstants.farms);

  // ── Reads ────────────────────────────────────────────────────────────────

  Future<InteractionModel?> getInteraction(String interactionId) async {
    final snap = await _interactionsCol.doc(interactionId).get();
    return snap.data();
  }

  Stream<InteractionModel?> watchInteraction(String interactionId) =>
      _interactionsCol.doc(interactionId).snapshots().map((s) => s.data());

  Stream<List<InteractionModel>> watchRequesterInteractions(
          String requesterId) =>
      _interactionsCol
          .where('requesterId', isEqualTo: requesterId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());

  Stream<List<InteractionModel>> watchRecipientInteractions(
          String recipientId) =>
      _interactionsCol
          .where('recipientId', isEqualTo: recipientId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());

  Future<InteractionLockModel?> getInteractionLock({
    required String requesterId,
    required String contextId,
  }) async {
    final id = InteractionLockModel.buildId(
        requesterId: requesterId, contextId: contextId);
    final snap = await _locksCol.doc(id).get();
    return snap.data();
  }

  // ── Create (atomic) ─────────────────────────────────────────────────────

  /// Creates a new interaction and its requester+context lock atomically:
  /// both writes happen inside one Firestore transaction, so two concurrent
  /// callers can never both observe "no open lock" and both create an open
  /// interaction — Firestore's transaction commit protocol guarantees that
  /// if two transactions read the same lock document, at most one of them
  /// can commit; the other is retried by the SDK against the now-updated
  /// lock and correctly throws [InteractionAlreadyOpenException] instead.
  ///
  /// Interaction documents always use a Firestore auto-generated id — never
  /// the deterministic `{requesterId}_{contextId}` id, which is reserved for
  /// the lock only, so that a requester's interaction history (including a
  /// declined/cancelled/completed one) is preserved when they later start a
  /// new interaction for the same context.
  ///
  /// VALIDATION BOUNDARY — read this before adding more client-side checks:
  /// - `contextType == 'land'`: this repository pre-checks that
  ///   `farms/{contextId}.ownerId == recipientId` before opening the
  ///   transaction, because `farms/{contextId}` is readable by any signed-in
  ///   user (see firestore.rules) — a safe, real early-failure check, not a
  ///   duplicated security decision.
  /// - `recipientRole == 'vet'` (or any other context): this repository does
  ///   **not** pre-check the recipient's role or verification status.
  ///   `users/{uid}` is only readable by its own owner
  ///   (`allow read: if isOwner(userId);`), so the client has no legitimate
  ///   way to read another user's role/isVerified before writing — doing so
  ///   would itself fail with permission-denied. That check is enforced
  ///   authoritatively by firestore.rules at write time; a rejection here
  ///   surfaces as [InteractionPermissionDeniedException]. Reconciling this
  ///   with the (uid-less) vets directory collection is explicitly deferred
  ///   to the vet entry-point phase — see Batch 1's final report.
  Future<String> createInteraction({
    required String requesterId,
    required String requesterRole,
    required String recipientId,
    required String recipientRole,
    required String interactionType,
    required String contextType,
    required String contextId,
    required String subject,
  }) async {
    if (requesterId.isEmpty || recipientId.isEmpty) {
      throw const InvalidInteractionRequestException(
          'requesterId and recipientId are required.');
    }
    if (requesterId == recipientId) {
      throw const InvalidInteractionRequestException(
          'You cannot start an interaction with yourself.');
    }
    if (contextId.isEmpty) {
      throw const InvalidInteractionRequestException(
          'contextId is required.');
    }
    if (subject.trim().isEmpty) {
      throw const InvalidInteractionRequestException(
          'Subject cannot be empty.');
    }

    if (contextType == 'land') {
      final farmSnap = await _farmsCol.doc(contextId).get();
      final ownerId = farmSnap.data()?['ownerId'] as String?;
      if (ownerId == null) {
        throw const InvalidInteractionRequestException(
            'The referenced land listing no longer exists.');
      }
      if (ownerId != recipientId) {
        throw const InvalidInteractionRequestException(
            'The recipient does not own this land listing.');
      }
    }

    final lockId = InteractionLockModel.buildId(
        requesterId: requesterId, contextId: contextId);
    final lockRef = _locksCol.doc(lockId);
    final interactionRef = _interactionsCol.doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final lockSnap = await transaction.get(lockRef);
        final existingLock = lockSnap.data();

        if (existingLock != null && existingLock.isOpen) {
          throw const InteractionAlreadyOpenException();
        }

        final now = DateTime.now();

        final interaction = InteractionModel(
          id: interactionRef.id,
          requesterId: requesterId,
          requesterRole: requesterRole,
          recipientId: recipientId,
          recipientRole: recipientRole,
          interactionType: interactionType,
          contextType: contextType,
          contextId: contextId,
          subject: subject,
          status: FirebaseConstants.interactionPending,
          createdAt: now,
        );
        transaction.set(interactionRef, interaction);

        final lock = InteractionLockModel(
          id: lockId,
          requesterId: requesterId,
          contextId: contextId,
          recipientId: recipientId,
          status: FirebaseConstants.interactionPending,
          currentInteractionId: interactionRef.id,
          updatedAt: now,
        );
        // .set() is correct whether the lock document previously existed
        // (re-request after a terminal status) or not (brand-new pair) —
        // Firestore classifies create/update by document existence, not by
        // which client API was called, so firestore.rules' separate
        // create/update branches still apply correctly either way.
        transaction.set(lockRef, lock);
      });
    } on InteractionAlreadyOpenException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const InteractionPermissionDeniedException();
      }
      throw InteractionTransactionFailedException(
          e.message ?? 'Failed to create the interaction. Please try again.');
    }

    return interactionRef.id;
  }
}
