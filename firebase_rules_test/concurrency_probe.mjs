// Batch 2 (Phase 3+4) concurrency proof — NOT a Batch 1 file, does not
// modify run.mjs. Run against a locally running Firestore emulator, never
// production. Uses the real configured project id ("jeevamitra").
//
// WHY THIS FILE EXISTS: fake_cloud_firestore (used by
// test/firebase/interaction_repository_test.dart) implements
// FirebaseFirestore.runTransaction() as a dummy with no real optimistic-
// concurrency/conflict detection — verified by reading its source
// (fake_cloud_firestore-3.1.0/lib/src/fake_cloud_firestore_instance.dart:
// `Transaction transaction = _DummyTransaction(); return await
// transactionHandler(transaction);` — no retry, no commit-time conflict
// check). Two "concurrent" calls against that fake would both read "no
// lock" before either writes, and BOTH would incorrectly succeed — not a
// bug in InteractionRepository, but a limitation of the fake. Dart-level
// unit tests therefore only prove the repository's *logic* (see
// interaction_repository_test.dart's header comment). The actual
// concurrent-safety claim (Batch 2 spec TEST 7: "only one OPEN interaction
// succeeds") can only be honestly proven against a Firestore engine that
// implements real transaction semantics — the local emulator does. This
// script mirrors InteractionRepository.createInteraction()'s exact
// transaction shape (read lock -> reject if open -> else write interaction
// + lock) in JS and fires two of them concurrently at the real emulator.
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  doc, setDoc, getDocs, collection, query, where, runTransaction, Timestamp,
} from 'firebase/firestore';

const PROJECT_ID = 'jeevamitra';

async function attemptCreateInteraction(db, args) {
  const { requesterId, requesterRole, recipientId, recipientRole, interactionType, contextType, contextId, subject } = args;
  const lockId = `${requesterId}_${contextId}`;
  const lockRef = doc(db, 'interactionLocks', lockId);
  const interactionRef = doc(collection(db, 'interactions'));

  await runTransaction(db, async (transaction) => {
    const lockSnap = await transaction.get(lockRef);
    if (lockSnap.exists()) {
      const status = lockSnap.data().status;
      if (['pending', 'accepted', 'active'].includes(status)) {
        throw new Error('ALREADY_OPEN');
      }
    }
    const now = Timestamp.now();
    transaction.set(interactionRef, {
      requesterId, requesterRole, recipientId, recipientRole,
      interactionType, contextType, contextId, subject,
      status: 'pending', createdAt: now,
      unreadCountRequester: 0, unreadCountRecipient: 0,
    });
    transaction.set(lockRef, {
      requesterId, contextId, recipientId,
      status: 'pending', currentInteractionId: interactionRef.id, updatedAt: now,
    });
  });

  return interactionRef.id;
}

let passed = 0;
let failed = 0;

function check(name, condition, detail) {
  if (condition) {
    passed++;
    console.log(`  PASS  ${name}`);
  } else {
    failed++;
    console.log(`  FAIL  ${name}`);
    if (detail) console.log(`        ${detail}`);
  }
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/farmer-1'), {
      uid: 'farmer-1', phone: '+911111111111', role: 'farmer', name: 'Farmer One',
      isProfileComplete: true, preferredLanguage: 'te',
    });
    await setDoc(doc(db, 'users/vet-1'), {
      uid: 'vet-1', phone: '+911111111114', role: 'vet', name: 'Dr Vet One',
      isProfileComplete: true, preferredLanguage: 'te', isVerified: true,
    });
  });

  const farmer1 = testEnv.authenticatedContext('farmer-1');
  const db = farmer1.firestore();

  console.log('\nconcurrent createInteraction — TEST 6 (rapid) + TEST 7 (concurrent)');

  // ── TEST 7: two genuinely concurrent transactions for the SAME pair ────
  const args = {
    requesterId: 'farmer-1', requesterRole: 'farmer',
    recipientId: 'vet-1', recipientRole: 'vet',
    interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
    subject: 'Concurrent attempt',
  };

  const results = await Promise.allSettled([
    attemptCreateInteraction(db, args),
    attemptCreateInteraction(db, { ...args, subject: 'Concurrent attempt (second tap)' }),
  ]);

  const succeeded = results.filter((r) => r.status === 'fulfilled');
  const rejected = results.filter((r) => r.status === 'rejected');

  check(
    'exactly one of two concurrent attempts succeeds',
    succeeded.length === 1,
    `succeeded=${succeeded.length} rejected=${rejected.length}`,
  );
  check(
    'exactly one of two concurrent attempts is rejected',
    rejected.length === 1,
    rejected[0] ? rejected[0].reason.message : '(none rejected)',
  );
  check(
    'the rejected attempt fails with the expected already-open signal',
    rejected.length === 1 &&
      (rejected[0].reason.message === 'ALREADY_OPEN' ||
        /already exists|ALREADY_EXISTS/i.test(rejected[0].reason.message)),
    rejected[0] ? rejected[0].reason.message : '(none rejected)',
  );

  const interactionsSnap = await getDocs(
    query(collection(db, 'interactions'), where('requesterId', '==', 'farmer-1')),
  );
  check(
    'exactly one interaction document exists for this requester+context pair',
    interactionsSnap.size === 1,
    `found ${interactionsSnap.size} interaction doc(s)`,
  );

  const lockSnap = await getDocs(
    query(collection(db, 'interactionLocks'), where('requesterId', '==', 'farmer-1')),
  );
  check('exactly one lock document exists', lockSnap.size === 1, `found ${lockSnap.size} lock doc(s)`);
  if (lockSnap.size === 1 && interactionsSnap.size === 1) {
    check(
      'the surviving lock points at the surviving interaction',
      lockSnap.docs[0].data().currentInteractionId === interactionsSnap.docs[0].id,
    );
  }

  // ── TEST 6: rapid sequential re-invocation against the real emulator ───
  const rapidResult = await attemptCreateInteraction(db, {
    ...args,
    requesterId: 'farmer-1',
    contextId: 'vet-1', // same pair — lock is already open from TEST 7 above
    subject: 'Rapid duplicate',
  }).then(
    () => 'succeeded',
    (e) => e.message,
  );
  check(
    'a further rapid duplicate against the still-open pair is also rejected',
    rapidResult === 'ALREADY_OPEN',
    `got: ${rapidResult}`,
  );

  console.log(`\n${passed} passed, ${failed} failed\n`);
  await testEnv.cleanup();
  if (failed > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
