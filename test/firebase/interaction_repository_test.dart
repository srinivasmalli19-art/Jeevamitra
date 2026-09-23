import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/data/repositories/interaction_repository.dart';

// NOTE ON CONCURRENCY TESTING (read before adding more "concurrent" tests
// here): fake_cloud_firestore's runTransaction is a dummy — it hands the
// handler a `_DummyTransaction` whose get()/set()/update() apply directly
// against the live in-memory store with no snapshot isolation and no
// conflict detection on commit (verified by reading
// fake_cloud_firestore's own source: `Transaction transaction =
// _DummyTransaction(); return await transactionHandler(transaction);` —
// no retry, no abort-on-conflicting-read). Two calls started via
// `Future.wait([...])` against this fake would both read "no lock" before
// either writes (their synchronous prefixes both reach the lock read before
// either's read Future resolves), so both would "succeed" and create two
// open interactions — not because InteractionRepository is wrong, but
// because the fake provides no real optimistic-concurrency guarantee to
// violate in the first place. Asserting real concurrent-safety (Batch 2
// spec's TEST 7) therefore requires the actual Firestore transaction
// engine, which the fake does not provide — that proof lives in
// firebase_rules_test/run.mjs against the real local Firestore emulator
// (see the "concurrent interactionLocks" probes there), not here. Tests in
// this file cover the repository's *logic* (TEST 1-6, 8, 9): what a single
// transaction attempt does given the lock state it observes.

InteractionRepository _repo(FakeFirebaseFirestore fs) =>
    InteractionRepository(firestore: fs);

Future<void> _seedFarm(FakeFirebaseFirestore fs, String id, String ownerId) =>
    fs.collection('farms').doc(id).set({'ownerId': ownerId, 'title': 'Test farm'});

Future<void> _seedTerminalPair(
  FakeFirebaseFirestore fs, {
  required String requesterId,
  required String contextId,
  required String recipientId,
  required String status,
  required String oldInteractionId,
}) async {
  await fs.collection('interactions').doc(oldInteractionId).set({
    'requesterId': requesterId,
    'requesterRole': 'farmer',
    'recipientId': recipientId,
    'recipientRole': 'vet',
    'interactionType': 'vet_consultation',
    'contextType': 'vet',
    'contextId': contextId,
    'subject': 'Old case',
    'status': status,
    'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    'acceptedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
    if (status == 'completed')
      'completedAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
    'unreadCountRequester': 0,
    'unreadCountRecipient': 0,
  });
  await fs.collection('interactionLocks').doc('${requesterId}_$contextId').set({
    'requesterId': requesterId,
    'contextId': contextId,
    'recipientId': recipientId,
    'status': status,
    'currentInteractionId': oldInteractionId,
    'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
  });
}

void main() {
  late FakeFirebaseFirestore firestore;
  late InteractionRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = _repo(firestore);
  });

  group('argument validation', () {
    test('rejects requesting yourself', () async {
      await expectLater(
        repo.createInteraction(
          requesterId: 'vet-1', requesterRole: 'vet',
          recipientId: 'vet-1', recipientRole: 'vet',
          interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
          subject: 'x',
        ),
        throwsA(isA<InvalidInteractionRequestException>()),
      );
    });

    test('rejects an empty subject', () async {
      await expectLater(
        repo.createInteraction(
          requesterId: 'farmer-1', requesterRole: 'farmer',
          recipientId: 'vet-1', recipientRole: 'vet',
          interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
          subject: '   ',
        ),
        throwsA(isA<InvalidInteractionRequestException>()),
      );
    });

    test('land context: succeeds when the recipient really owns the farm', () async {
      await _seedFarm(firestore, 'farm-9', 'farmer-2');
      final id = await repo.createInteraction(
        requesterId: 'shepherd-1', requesterRole: 'shepherd',
        recipientId: 'farmer-2', recipientRole: 'farmer',
        interactionType: 'land_inquiry', contextType: 'land', contextId: 'farm-9',
        subject: 'Interested in your land',
      );
      expect(id, isNotEmpty);
    });

    test('land context: rejects when the named recipient does not own the farm', () async {
      await _seedFarm(firestore, 'farm-9', 'farmer-2');
      await expectLater(
        repo.createInteraction(
          requesterId: 'shepherd-1', requesterRole: 'shepherd',
          recipientId: 'farmer-1', recipientRole: 'farmer',
          interactionType: 'land_inquiry', contextType: 'land', contextId: 'farm-9',
          subject: 'Interested in your land',
        ),
        throwsA(isA<InvalidInteractionRequestException>()),
      );
    });
  });

  group('TEST 1 — no existing lock', () {
    test('creates exactly one interaction and exactly one lock', () async {
      final id = await repo.createInteraction(
        requesterId: 'farmer-1', requesterRole: 'farmer',
        recipientId: 'vet-1', recipientRole: 'vet',
        interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
        subject: 'Sick cow',
      );

      final interactions = await firestore.collection('interactions').get();
      expect(interactions.docs, hasLength(1));
      expect(interactions.docs.first.id, id);
      expect(interactions.docs.first.data()['status'], 'pending');
      expect(interactions.docs.first.data()['requesterId'], 'farmer-1');

      final locks = await firestore.collection('interactionLocks').get();
      expect(locks.docs, hasLength(1));
      expect(locks.docs.first.id, 'farmer-1_vet-1');
      expect(locks.docs.first.data()['currentInteractionId'], id);
      expect(locks.docs.first.data()['status'], 'pending');
    });
  });

  group('TEST 2 — existing OPEN lock', () {
    test('rejects the new request, creates no second interaction, leaves the lock unchanged', () async {
      final firstId = await repo.createInteraction(
        requesterId: 'farmer-1', requesterRole: 'farmer',
        recipientId: 'vet-1', recipientRole: 'vet',
        interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
        subject: 'Sick cow',
      );

      await expectLater(
        repo.createInteraction(
          requesterId: 'farmer-1', requesterRole: 'farmer',
          recipientId: 'vet-1', recipientRole: 'vet',
          interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
          subject: 'Second attempt',
        ),
        throwsA(isA<InteractionAlreadyOpenException>()),
      );

      final interactions = await firestore.collection('interactions').get();
      expect(interactions.docs, hasLength(1));

      final lockDoc =
          await firestore.collection('interactionLocks').doc('farmer-1_vet-1').get();
      expect(lockDoc.data()!['currentInteractionId'], firstId);
      expect(lockDoc.data()!['status'], 'pending');
    });

    test('also rejects once the lock has advanced to accepted/active', () async {
      await repo.createInteraction(
        requesterId: 'farmer-1', requesterRole: 'farmer',
        recipientId: 'vet-1', recipientRole: 'vet',
        interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
        subject: 'Sick cow',
      );
      await firestore.collection('interactionLocks').doc('farmer-1_vet-1').update({
        'status': 'active',
      });

      await expectLater(
        repo.createInteraction(
          requesterId: 'farmer-1', requesterRole: 'farmer',
          recipientId: 'vet-1', recipientRole: 'vet',
          interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
          subject: 'Second attempt',
        ),
        throwsA(isA<InteractionAlreadyOpenException>()),
      );
    });
  });

  for (final status in ['declined', 'cancelled', 'completed']) {
    group('TEST ${status == 'declined' ? 3 : status == 'cancelled' ? 4 : 5} — existing $status lock', () {
      test('creates a new interaction with a new auto-id and updates the lock', () async {
        await _seedTerminalPair(
          firestore,
          requesterId: 'farmer-1',
          contextId: 'vet-1',
          recipientId: 'vet-1',
          status: status,
          oldInteractionId: 'old-int',
        );

        final newId = await repo.createInteraction(
          requesterId: 'farmer-1', requesterRole: 'farmer',
          recipientId: 'vet-1', recipientRole: 'vet',
          interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
          subject: 'New case',
        );

        expect(newId, isNot('old-int'));

        final oldDoc = await firestore.collection('interactions').doc('old-int').get();
        expect(oldDoc.data()!['status'], status); // TEST 9: untouched

        final newDoc = await firestore.collection('interactions').doc(newId).get();
        expect(newDoc.data()!['status'], 'pending');

        final lockDoc =
            await firestore.collection('interactionLocks').doc('farmer-1_vet-1').get();
        expect(lockDoc.data()!['currentInteractionId'], newId);
        expect(lockDoc.data()!['status'], 'pending');

        final allInteractions = await firestore.collection('interactions').get();
        expect(allInteractions.docs, hasLength(2)); // old + new both present
      });
    });
  }

  group('TEST 6 — rapid duplicate invocation', () {
    test('a second call issued immediately after the first still resolves against the '
        'lock the first one just wrote, so only one OPEN interaction ever exists', () async {
      final firstId = await repo.createInteraction(
        requesterId: 'farmer-1', requesterRole: 'farmer',
        recipientId: 'vet-1', recipientRole: 'vet',
        interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
        subject: 'Sick cow',
      );

      // Simulates a double-tap: the same request fired again before the UI
      // had a chance to disable the button.
      await expectLater(
        repo.createInteraction(
          requesterId: 'farmer-1', requesterRole: 'farmer',
          recipientId: 'vet-1', recipientRole: 'vet',
          interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
          subject: 'Sick cow',
        ),
        throwsA(isA<InteractionAlreadyOpenException>()),
      );

      final interactions = await firestore.collection('interactions').get();
      expect(interactions.docs, hasLength(1));
      expect(interactions.docs.first.id, firstId);
    });
  });

  group('TEST 8 — failure leaves no partial interaction/lock pair', () {
    test('a rejected create() commits neither the interaction nor a lock mutation', () async {
      await repo.createInteraction(
        requesterId: 'farmer-1', requesterRole: 'farmer',
        recipientId: 'vet-1', recipientRole: 'vet',
        interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
        subject: 'Sick cow',
      );

      final beforeInteractions = (await firestore.collection('interactions').get()).docs.length;
      final beforeLock = (await firestore.collection('interactionLocks').doc('farmer-1_vet-1').get()).data();

      // createInteraction() already allocated an auto-id DocumentReference
      // for this attempt (interactionRef = _interactionsCol.doc()) before
      // entering the transaction — allocating a client-side id never writes
      // anything by itself. Only transaction.set() inside a *committed*
      // transaction persists a document, and the transaction here throws
      // before reaching that call, so nothing beyond the original doc/lock
      // should exist afterwards.
      await expectLater(
        repo.createInteraction(
          requesterId: 'farmer-1', requesterRole: 'farmer',
          recipientId: 'vet-1', recipientRole: 'vet',
          interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
          subject: 'Second attempt',
        ),
        throwsA(isA<InteractionAlreadyOpenException>()),
      );

      final afterInteractions = (await firestore.collection('interactions').get()).docs.length;
      final afterLock = (await firestore.collection('interactionLocks').doc('farmer-1_vet-1').get()).data();

      expect(afterInteractions, beforeInteractions);
      expect(afterLock, beforeLock);
    });
  });

  group('TEST 9 — historical interaction preservation', () {
    test('an old completed interaction is fully unchanged once a new one is created', () async {
      await _seedTerminalPair(
        firestore,
        requesterId: 'farmer-1',
        contextId: 'vet-1',
        recipientId: 'vet-1',
        status: 'completed',
        oldInteractionId: 'old-int',
      );
      final oldBefore = (await firestore.collection('interactions').doc('old-int').get()).data();

      final newId = await repo.createInteraction(
        requesterId: 'farmer-1', requesterRole: 'farmer',
        recipientId: 'vet-1', recipientRole: 'vet',
        interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
        subject: 'Follow-up case',
      );

      final oldAfter = (await firestore.collection('interactions').doc('old-int').get()).data();
      expect(oldAfter, oldBefore); // byte-for-byte unchanged
      expect(newId, isNot('old-int'));

      final lockDoc =
          await firestore.collection('interactionLocks').doc('farmer-1_vet-1').get();
      expect(lockDoc.data()!['currentInteractionId'], newId);
      expect(lockDoc.data()!['currentInteractionId'], isNot('old-int'));
    });
  });

  group('reads', () {
    test('getInteraction / watchInteraction / getInteractionLock reflect what createInteraction wrote', () async {
      final id = await repo.createInteraction(
        requesterId: 'farmer-1', requesterRole: 'farmer',
        recipientId: 'vet-1', recipientRole: 'vet',
        interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
        subject: 'Sick cow',
      );

      final got = await repo.getInteraction(id);
      expect(got, isNotNull);
      expect(got!.id, id);

      final watched = await repo.watchInteraction(id).first;
      expect(watched!.id, id);

      final lock = await repo.getInteractionLock(requesterId: 'farmer-1', contextId: 'vet-1');
      expect(lock, isNotNull);
      expect(lock!.currentInteractionId, id);
    });

    test('watchRequesterInteractions / watchRecipientInteractions filter correctly', () async {
      await repo.createInteraction(
        requesterId: 'farmer-1', requesterRole: 'farmer',
        recipientId: 'vet-1', recipientRole: 'vet',
        interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
        subject: 'Case A',
      );
      await repo.createInteraction(
        requesterId: 'farmer-2', requesterRole: 'farmer',
        recipientId: 'vet-1', recipientRole: 'vet',
        interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-2',
        subject: 'Case B',
      );

      final requesterView = await repo.watchRequesterInteractions('farmer-1').first;
      expect(requesterView, hasLength(1));
      expect(requesterView.first.subject, 'Case A');

      final recipientView = await repo.watchRecipientInteractions('vet-1').first;
      expect(recipientView, hasLength(2));
    });
  });
}
