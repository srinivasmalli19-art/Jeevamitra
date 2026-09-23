import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/models/interaction_model.dart';

InteractionModel _interaction({
  String id = '',
  String requesterId = 'farmer-1',
  String recipientId = 'vet-1',
  String status = 'pending',
  DateTime? acceptedAt,
  DateTime? completedAt,
  DateTime? lastMessageAt,
  String? lastMessageText,
  String? lastMessageSenderId,
  int unreadCountRequester = 0,
  int unreadCountRecipient = 0,
}) {
  return InteractionModel(
    id: id,
    requesterId: requesterId,
    requesterRole: 'farmer',
    recipientId: recipientId,
    recipientRole: 'vet',
    interactionType: 'vet_consultation',
    contextType: 'vet',
    contextId: 'vet-1',
    subject: 'Sick cow',
    status: status,
    createdAt: DateTime(2026, 7, 1),
    acceptedAt: acceptedAt,
    completedAt: completedAt,
    lastMessageAt: lastMessageAt,
    lastMessageText: lastMessageText,
    lastMessageSenderId: lastMessageSenderId,
    unreadCountRequester: unreadCountRequester,
    unreadCountRecipient: unreadCountRecipient,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('round-trip', () {
    test('required fields only survive write and read back unchanged', () async {
      final model = _interaction();
      final ref = await firestore.collection('interactions').add(model.toFirestore());
      final snap = await ref.get();
      final read = InteractionModel.fromFirestore(snap);

      expect(read.requesterId, 'farmer-1');
      expect(read.requesterRole, 'farmer');
      expect(read.recipientId, 'vet-1');
      expect(read.recipientRole, 'vet');
      expect(read.interactionType, 'vet_consultation');
      expect(read.contextType, 'vet');
      expect(read.contextId, 'vet-1');
      expect(read.subject, 'Sick cow');
      expect(read.status, 'pending');
      expect(read.createdAt, DateTime(2026, 7, 1));
      expect(read.acceptedAt, isNull);
      expect(read.completedAt, isNull);
      expect(read.lastMessageAt, isNull);
      expect(read.lastMessageText, isNull);
      expect(read.lastMessageSenderId, isNull);
      expect(read.unreadCountRequester, 0);
      expect(read.unreadCountRecipient, 0);
    });

    test('optional fields present survive write and read back unchanged', () async {
      final model = _interaction(
        status: 'active',
        acceptedAt: DateTime(2026, 7, 2),
        lastMessageAt: DateTime(2026, 7, 3),
        lastMessageText: 'Hello doctor',
        lastMessageSenderId: 'farmer-1',
        unreadCountRequester: 0,
        unreadCountRecipient: 2,
      );
      final ref = await firestore.collection('interactions').add(model.toFirestore());
      final snap = await ref.get();
      final read = InteractionModel.fromFirestore(snap);

      expect(read.status, 'active');
      expect(read.acceptedAt, DateTime(2026, 7, 2));
      expect(read.lastMessageAt, DateTime(2026, 7, 3));
      expect(read.lastMessageText, 'Hello doctor');
      expect(read.lastMessageSenderId, 'farmer-1');
      expect(read.unreadCountRecipient, 2);
    });

    test('completed interaction preserves completedAt', () async {
      final model = _interaction(status: 'completed', completedAt: DateTime(2026, 7, 10));
      final ref = await firestore.collection('interactions').add(model.toFirestore());
      final snap = await ref.get();
      final read = InteractionModel.fromFirestore(snap);

      expect(read.status, 'completed');
      expect(read.completedAt, DateTime(2026, 7, 10));
    });

    test('missing status field on legacy-shaped data defaults to pending', () async {
      final ref = await firestore.collection('interactions').add({
        'requesterId': 'farmer-1',
        'requesterRole': 'farmer',
        'recipientId': 'vet-1',
        'recipientRole': 'vet',
        'interactionType': 'vet_consultation',
        'contextType': 'vet',
        'contextId': 'vet-1',
        'subject': 'Sick cow',
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 1)),
      });
      final snap = await ref.get();
      final read = InteractionModel.fromFirestore(snap);
      expect(read.status, 'pending');
    });
  });

  group('status getters', () {
    test('isOpen is true for pending, accepted, active', () {
      expect(_interaction(status: 'pending').isOpen, isTrue);
      expect(_interaction(status: 'accepted').isOpen, isTrue);
      expect(_interaction(status: 'active').isOpen, isTrue);
      expect(_interaction(status: 'declined').isOpen, isFalse);
    });

    test('isTerminal is true for declined, cancelled, completed', () {
      expect(_interaction(status: 'declined').isTerminal, isTrue);
      expect(_interaction(status: 'cancelled').isTerminal, isTrue);
      expect(_interaction(status: 'completed').isTerminal, isTrue);
      expect(_interaction(status: 'pending').isTerminal, isFalse);
    });

    test('canMessage is true only once accepted or active', () {
      expect(_interaction(status: 'pending').canMessage, isFalse);
      expect(_interaction(status: 'accepted').canMessage, isTrue);
      expect(_interaction(status: 'active').canMessage, isTrue);
      expect(_interaction(status: 'declined').canMessage, isFalse);
    });
  });

  group('copyWithModel', () {
    test('updates only the passed fields, preserving the rest', () async {
      final model = _interaction();
      final updated = model.copyWithModel(status: 'accepted', acceptedAt: DateTime(2026, 7, 2));

      expect(updated.status, 'accepted');
      expect(updated.acceptedAt, DateTime(2026, 7, 2));
      expect(updated.requesterId, model.requesterId);
      expect(updated.contextId, model.contextId);
      expect(updated.createdAt, model.createdAt);
    });
  });
}
