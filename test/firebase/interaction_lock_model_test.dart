import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/models/interaction_lock_model.dart';

InteractionLockModel _lock({
  String? id,
  String requesterId = 'farmer-1',
  String contextId = 'vet-1',
  String recipientId = 'vet-1',
  String status = 'pending',
  String currentInteractionId = 'int-1',
  DateTime? updatedAt,
}) {
  return InteractionLockModel(
    id: id ?? InteractionLockModel.buildId(requesterId: requesterId, contextId: contextId),
    requesterId: requesterId,
    contextId: contextId,
    recipientId: recipientId,
    status: status,
    currentInteractionId: currentInteractionId,
    updatedAt: updatedAt ?? DateTime(2026, 7, 1),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('buildId', () {
    test('is deterministic for the same requester+context pair', () {
      final a = InteractionLockModel.buildId(requesterId: 'farmer-1', contextId: 'vet-1');
      final b = InteractionLockModel.buildId(requesterId: 'farmer-1', contextId: 'vet-1');
      expect(a, b);
      expect(a, 'farmer-1_vet-1');
    });

    test('differs for different requesters or contexts', () {
      final a = InteractionLockModel.buildId(requesterId: 'farmer-1', contextId: 'vet-1');
      final b = InteractionLockModel.buildId(requesterId: 'farmer-2', contextId: 'vet-1');
      final c = InteractionLockModel.buildId(requesterId: 'farmer-1', contextId: 'vet-2');
      expect(a, isNot(b));
      expect(a, isNot(c));
    });
  });

  group('round-trip', () {
    test('all fields survive write and read back unchanged', () async {
      final model = _lock();
      await firestore.collection('interactionLocks').doc(model.id).set(model.toFirestore());
      final snap = await firestore.collection('interactionLocks').doc(model.id).get();
      final read = InteractionLockModel.fromFirestore(snap);

      expect(read.id, 'farmer-1_vet-1');
      expect(read.requesterId, 'farmer-1');
      expect(read.contextId, 'vet-1');
      expect(read.recipientId, 'vet-1');
      expect(read.status, 'pending');
      expect(read.currentInteractionId, 'int-1');
      expect(read.updatedAt, DateTime(2026, 7, 1));
    });

    test('missing status field on legacy-shaped data defaults to pending', () async {
      await firestore.collection('interactionLocks').doc('farmer-1_vet-1').set({
        'requesterId': 'farmer-1',
        'contextId': 'vet-1',
        'recipientId': 'vet-1',
        'currentInteractionId': 'int-1',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 7, 1)),
      });
      final snap = await firestore.collection('interactionLocks').doc('farmer-1_vet-1').get();
      final read = InteractionLockModel.fromFirestore(snap);
      expect(read.status, 'pending');
    });
  });

  group('status getters', () {
    test('isOpen is true for pending, accepted, active', () {
      expect(_lock(status: 'pending').isOpen, isTrue);
      expect(_lock(status: 'accepted').isOpen, isTrue);
      expect(_lock(status: 'active').isOpen, isTrue);
      expect(_lock(status: 'completed').isOpen, isFalse);
    });

    test('isTerminal is true for declined, cancelled, completed', () {
      expect(_lock(status: 'declined').isTerminal, isTrue);
      expect(_lock(status: 'cancelled').isTerminal, isTrue);
      expect(_lock(status: 'completed').isTerminal, isTrue);
      expect(_lock(status: 'pending').isTerminal, isFalse);
    });
  });

  group('re-request-after-completion lifecycle', () {
    test(
        'the same requester+context pair reuses the same lock document id '
        'across a completed interaction and a brand-new one, only the '
        'pointer fields change', () async {
      final firstLock = _lock(status: 'pending', currentInteractionId: 'int-1');
      await firestore
          .collection('interactionLocks')
          .doc(firstLock.id)
          .set(firstLock.toFirestore());

      final completedLock = firstLock.copyWithModel(
        status: 'completed',
        updatedAt: DateTime(2026, 7, 5),
      );
      await firestore
          .collection('interactionLocks')
          .doc(completedLock.id)
          .set(completedLock.toFirestore());

      final reReqLock = InteractionLockModel(
        id: InteractionLockModel.buildId(
            requesterId: 'farmer-1', contextId: 'vet-1'),
        requesterId: 'farmer-1',
        contextId: 'vet-1',
        recipientId: 'vet-1',
        status: 'pending',
        currentInteractionId: 'int-2',
        updatedAt: DateTime(2026, 8, 1),
      );
      await firestore
          .collection('interactionLocks')
          .doc(reReqLock.id)
          .set(reReqLock.toFirestore());

      expect(reReqLock.id, firstLock.id);

      final snap = await firestore.collection('interactionLocks').doc(firstLock.id).get();
      final read = InteractionLockModel.fromFirestore(snap);
      expect(read.status, 'pending');
      expect(read.currentInteractionId, 'int-2');
      expect(read.updatedAt, DateTime(2026, 8, 1));

      final onlyOneLockExists =
          await firestore.collection('interactionLocks').get();
      expect(onlyOneLockExists.docs, hasLength(1));
    });
  });

  group('copyWithModel', () {
    test('updates only the passed fields, preserving the rest', () {
      final model = _lock();
      final updated = model.copyWithModel(
        status: 'accepted',
        updatedAt: DateTime(2026, 7, 2),
      );

      expect(updated.status, 'accepted');
      expect(updated.updatedAt, DateTime(2026, 7, 2));
      expect(updated.currentInteractionId, model.currentInteractionId);
      expect(updated.requesterId, model.requesterId);
      expect(updated.id, model.id);
    });
  });
}
