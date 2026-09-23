// Firebase Emulator Suite rules probes for the interaction system (Batch 1,
// Phase 1 + Phase 2 only). Run against a locally running emulator — never
// production. Uses the real configured project id ("jeevamitra", from
// .firebaserc) because Storage's firestore.get() cross-service checks fail
// to resolve under an arbitrary/mismatched project id in the emulator.
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, setDoc, getDoc, updateDoc, deleteDoc, addDoc, collection, serverTimestamp, Timestamp,
} from 'firebase/firestore';
import {
  ref, uploadBytes, getBytes,
} from 'firebase/storage';

const PROJECT_ID = 'jeevamitra';

let passed = 0;
let failed = 0;
const failures = [];

async function check(name, fn) {
  try {
    await fn();
    passed++;
    console.log(`  PASS  ${name}`);
  } catch (err) {
    failed++;
    failures.push({ name, err });
    console.log(`  FAIL  ${name}`);
    console.log(`        ${err.message.split('\n')[0]}`);
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
    storage: {
      rules: readFileSync('../storage.rules', 'utf8'),
      host: '127.0.0.1',
      port: 9199,
    },
  });

  await testEnv.clearFirestore();
  await testEnv.clearStorage();

  // ── Seed fixtures with rules disabled ─────────────────────────────────
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, 'users/farmer-1'), {
      uid: 'farmer-1', phone: '+911111111111', role: 'farmer', name: 'Farmer One',
      isProfileComplete: true, preferredLanguage: 'te',
    });
    await setDoc(doc(db, 'users/farmer-2'), {
      uid: 'farmer-2', phone: '+911111111112', role: 'farmer', name: 'Farmer Two',
      isProfileComplete: true, preferredLanguage: 'te',
    });
    await setDoc(doc(db, 'users/shepherd-1'), {
      uid: 'shepherd-1', phone: '+911111111113', role: 'shepherd', name: 'Shepherd One',
      isProfileComplete: true, preferredLanguage: 'te',
    });
    await setDoc(doc(db, 'users/vet-1'), {
      uid: 'vet-1', phone: '+911111111114', role: 'vet', name: 'Dr Vet One',
      isProfileComplete: true, preferredLanguage: 'te', isVerified: true,
    });
    await setDoc(doc(db, 'users/vet-unverified'), {
      uid: 'vet-unverified', phone: '+911111111115', role: 'vet', name: 'Dr Unverified',
      isProfileComplete: true, preferredLanguage: 'te', isVerified: false,
    });

    await setDoc(doc(db, 'farms/farm-9'), {
      ownerId: 'farmer-2', title: 'Green Pasture', village: 'Narasaraopet',
    });

    // An open (pending) interaction from farmer-1 -> vet-1, plus its lock.
    await setDoc(doc(db, 'interactions/int-open'), {
      requesterId: 'farmer-1', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: 'Sick cow', status: 'pending',
      createdAt: Timestamp.fromDate(new Date('2026-07-01')),
      unreadCountRequester: 0, unreadCountRecipient: 0,
    });
    await setDoc(doc(db, 'interactionLocks/farmer-1_vet-1'), {
      requesterId: 'farmer-1', contextId: 'vet-1', recipientId: 'vet-1',
      status: 'pending', currentInteractionId: 'int-open',
      updatedAt: Timestamp.fromDate(new Date('2026-07-01')),
    });

    // A second, untouched pending interaction — kept separate from int-open
    // (which 8g/8h mutate to 'accepted') so the "messaging blocked while
    // still pending" probe (16) isn't affected by test ordering.
    await setDoc(doc(db, 'interactions/int-pending-only'), {
      requesterId: 'farmer-1', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: 'Another case', status: 'pending',
      createdAt: Timestamp.fromDate(new Date('2026-07-01')),
      unreadCountRequester: 0, unreadCountRecipient: 0,
    });

    // An accepted interaction between farmer-1 and vet-1 for messaging tests.
    await setDoc(doc(db, 'interactions/int-accepted'), {
      requesterId: 'farmer-1', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: 'Goat fever', status: 'accepted',
      createdAt: Timestamp.fromDate(new Date('2026-06-01')),
      acceptedAt: Timestamp.fromDate(new Date('2026-06-02')),
      unreadCountRequester: 0, unreadCountRecipient: 0,
    });
    await setDoc(doc(db, 'interactions/int-accepted/messages/msg-1'), {
      senderId: 'farmer-1', senderRole: 'farmer', type: 'text', text: 'Hello',
      createdAt: Timestamp.fromDate(new Date('2026-06-02')),
    });

    // A terminal (completed) interaction/lock for the re-request scenario.
    await setDoc(doc(db, 'interactions/int-completed'), {
      requesterId: 'farmer-1', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1-old',
      subject: 'Old case', status: 'completed',
      createdAt: Timestamp.fromDate(new Date('2026-01-01')),
      acceptedAt: Timestamp.fromDate(new Date('2026-01-02')),
      completedAt: Timestamp.fromDate(new Date('2026-01-05')),
      unreadCountRequester: 0, unreadCountRecipient: 0,
    });
    await setDoc(doc(db, 'interactionLocks/farmer-1_vet-1-old'), {
      requesterId: 'farmer-1', contextId: 'vet-1-old', recipientId: 'vet-1',
      status: 'completed', currentInteractionId: 'int-completed',
      updatedAt: Timestamp.fromDate(new Date('2026-01-05')),
    });
  });

  const farmer1 = testEnv.authenticatedContext('farmer-1');
  const farmer2 = testEnv.authenticatedContext('farmer-2');
  const shepherd1 = testEnv.authenticatedContext('shepherd-1');
  const vet1 = testEnv.authenticatedContext('vet-1');
  const vetUnverified = testEnv.authenticatedContext('vet-unverified');
  const anon = testEnv.unauthenticatedContext();

  // .firestore()/.storage() must be called exactly once per context — a
  // second call re-runs initializeFirestore() on the same underlying app
  // and throws "Firestore has already been started". Cache the instances.
  const firestoreByCtx = new Map();
  const db = (ctx) => {
    if (!firestoreByCtx.has(ctx)) firestoreByCtx.set(ctx, ctx.firestore());
    return firestoreByCtx.get(ctx);
  };
  const storageByCtx = new Map();
  const storageOf = (ctx) => {
    if (!storageByCtx.has(ctx)) storageByCtx.set(ctx, ctx.storage());
    return storageByCtx.get(ctx);
  };

  // ── 1-8h: interactions ───────────────────────────────────────────────
  console.log('\ninteractions');

  await check('1. requester can create a valid interaction against a verified vet', () =>
    assertSucceeds(setDoc(doc(db(farmer2), 'interactions/int-new-1'), {
      requesterId: 'farmer-2', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: 'New case', status: 'pending',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
    })));

  await check('2. create is rejected when recipient is an unverified vet', () =>
    assertFails(setDoc(doc(db(farmer2), 'interactions/int-new-2'), {
      requesterId: 'farmer-2', requesterRole: 'farmer',
      recipientId: 'vet-unverified', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-unverified',
      subject: 'New case', status: 'pending',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
    })));

  await check('3. create is rejected when requesterId does not match auth.uid', () =>
    assertFails(setDoc(doc(db(farmer2), 'interactions/int-new-3'), {
      requesterId: 'farmer-1', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: 'New case', status: 'pending',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
    })));

  await check('4. create is rejected when requesterRole does not match the real user role', () =>
    assertFails(setDoc(doc(db(shepherd1), 'interactions/int-new-4'), {
      requesterId: 'shepherd-1', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: 'New case', status: 'pending',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
    })));

  await check('5. land-context create succeeds when recipient really owns the farm', () =>
    assertSucceeds(setDoc(doc(db(shepherd1), 'interactions/int-new-5'), {
      requesterId: 'shepherd-1', requesterRole: 'shepherd',
      recipientId: 'farmer-2', recipientRole: 'farmer',
      interactionType: 'land_inquiry', contextType: 'land', contextId: 'farm-9',
      subject: 'Interested in your land', status: 'pending',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
    })));

  await check('6. land-context create is rejected when recipient does not own the farm', () =>
    assertFails(setDoc(doc(db(shepherd1), 'interactions/int-new-6'), {
      requesterId: 'shepherd-1', requesterRole: 'shepherd',
      recipientId: 'farmer-1', recipientRole: 'farmer',
      interactionType: 'land_inquiry', contextType: 'land', contextId: 'farm-9',
      subject: 'Interested in your land', status: 'pending',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
    })));

  await check('7. create is rejected when requesting yourself', () =>
    assertFails(setDoc(doc(db(vet1), 'interactions/int-new-7'), {
      requesterId: 'vet-1', requesterRole: 'vet',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: 'New case', status: 'pending',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
    })));

  await check('8. create is rejected with a non-pending initial status', () =>
    assertFails(setDoc(doc(db(farmer2), 'interactions/int-new-8'), {
      requesterId: 'farmer-2', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: 'New case', status: 'accepted',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
    })));

  await check('8b. create is rejected with an empty subject', () =>
    assertFails(setDoc(doc(db(farmer2), 'interactions/int-new-8b'), {
      requesterId: 'farmer-2', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: '', status: 'pending',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
    })));

  await check('8c. create is rejected when a lastMessage* field is present at creation', () =>
    assertFails(setDoc(doc(db(farmer2), 'interactions/int-new-8c'), {
      requesterId: 'farmer-2', requesterRole: 'farmer',
      recipientId: 'vet-1', recipientRole: 'vet',
      interactionType: 'vet_consultation', contextType: 'vet', contextId: 'vet-1',
      subject: 'New case', status: 'pending',
      createdAt: Timestamp.now(), unreadCountRequester: 0, unreadCountRecipient: 0,
      lastMessageText: 'sneaky',
    })));

  await check('8d. a participant (requester) can read the open interaction', () =>
    assertSucceeds(getDoc(doc(db(farmer1), 'interactions/int-open'))));

  await check('8e. a participant (recipient) can read the open interaction', () =>
    assertSucceeds(getDoc(doc(db(vet1), 'interactions/int-open'))));

  await check('8f. a non-participant cannot read the interaction', () =>
    assertFails(getDoc(doc(db(shepherd1), 'interactions/int-open'))));

  await check('8g. the recipient can accept a pending interaction', () =>
    assertSucceeds(updateDoc(doc(db(vet1), 'interactions/int-open'), {
      status: 'accepted', acceptedAt: Timestamp.now(),
    })));

  await check('8h. the requester cannot accept their own pending interaction', () =>
    assertFails(updateDoc(doc(db(farmer1), 'interactions/int-open'), {
      status: 'accepted', acceptedAt: Timestamp.now(),
    })));

  // ── 9-12b: interactionLocks ───────────────────────────────────────────
  console.log('\ninteractionLocks');

  await check('9a. requester can create a lock for a brand-new pair', () =>
    assertSucceeds(setDoc(doc(db(farmer2), 'interactionLocks/farmer-2_vet-1'), {
      requesterId: 'farmer-2', contextId: 'vet-1', recipientId: 'vet-1',
      status: 'pending', currentInteractionId: 'int-new-1',
      updatedAt: Timestamp.now(),
    })));

  await check('9b. create is rejected when the doc id does not match requesterId_contextId', () =>
    assertFails(setDoc(doc(db(farmer2), 'interactionLocks/wrong-id'), {
      requesterId: 'farmer-2', contextId: 'vet-1', recipientId: 'vet-1',
      status: 'pending', currentInteractionId: 'int-x',
      updatedAt: Timestamp.now(),
    })));

  await check('10. participant can read a lock', () =>
    assertSucceeds(getDoc(doc(db(farmer1), 'interactionLocks/farmer-1_vet-1'))));

  await check('11. non-participant cannot read a lock', () =>
    assertFails(getDoc(doc(db(shepherd1), 'interactionLocks/farmer-1_vet-1'))));

  await check('12a. open lock rejects a second create-equivalent (same status, different interaction id)', () =>
    assertFails(updateDoc(doc(db(farmer1), 'interactionLocks/farmer-1_vet-1'), {
      status: 'pending', currentInteractionId: 'int-imposter',
      updatedAt: Timestamp.now(),
    })));

  await check('12b. a terminal lock CAN be reopened by its requester with a new interaction id (re-request)', () =>
    assertSucceeds(updateDoc(doc(db(farmer1), 'interactionLocks/farmer-1_vet-1-old'), {
      status: 'pending', currentInteractionId: 'int-rerequest',
      updatedAt: Timestamp.now(),
    })));

  await check('12c. re-request update is rejected if it reuses the same (now-terminal) interaction id', () =>
    assertFails(updateDoc(doc(db(farmer1), 'interactionLocks/farmer-1_vet-1-old'), {
      status: 'pending', currentInteractionId: 'int-completed',
      updatedAt: Timestamp.now(),
    })));

  await check('12d. someone other than the requester cannot reopen a terminal lock', () =>
    assertFails(updateDoc(doc(db(vet1), 'interactionLocks/farmer-1_vet-1-old'), {
      status: 'pending', currentInteractionId: 'int-hijack',
      updatedAt: Timestamp.now(),
    })));

  await check('12e. valid forward transition (open -> accepted, same interaction id) succeeds', () =>
    assertSucceeds(updateDoc(doc(db(vet1), 'interactionLocks/farmer-1_vet-1'), {
      status: 'accepted', currentInteractionId: 'int-open',
      updatedAt: Timestamp.now(),
    })));

  await check('12f. lock delete is always rejected', () =>
    assertFails(deleteDoc(doc(db(farmer1), 'interactionLocks/farmer-1_vet-1'))));

  // ── 13-18e: messages ───────────────────────────────────────────────────
  console.log('\ninteractions/{id}/messages');

  await check('13. a participant can read messages once accepted', () =>
    assertSucceeds(getDoc(doc(db(farmer1), 'interactions/int-accepted/messages/msg-1'))));

  await check('14. a non-participant cannot read messages', () =>
    assertFails(getDoc(doc(db(shepherd1), 'interactions/int-accepted/messages/msg-1'))));

  await check('15. a participant can send a text message once accepted', () =>
    assertSucceeds(setDoc(doc(db(farmer1), 'interactions/int-accepted/messages/msg-2'), {
      senderId: 'farmer-1', senderRole: 'farmer', type: 'text', text: 'Update?',
      createdAt: Timestamp.now(),
    })));

  await check('16. sending a message is rejected while the interaction is still pending', () =>
    assertFails(setDoc(doc(db(farmer1), 'interactions/int-pending-only/messages/msg-x'), {
      senderId: 'farmer-1', senderRole: 'farmer', type: 'text', text: 'Too early',
      createdAt: Timestamp.now(),
    })));

  await check('17. a client cannot create a system message', () =>
    assertFails(setDoc(doc(db(farmer1), 'interactions/int-accepted/messages/msg-3'), {
      senderId: 'farmer-1', senderRole: 'farmer', type: 'system', text: 'faked',
      createdAt: Timestamp.now(),
    })));

  await check('18. senderId spoofing another user is rejected', () =>
    assertFails(setDoc(doc(db(farmer1), 'interactions/int-accepted/messages/msg-4'), {
      senderId: 'vet-1', senderRole: 'vet', type: 'text', text: 'spoofed',
      createdAt: Timestamp.now(),
    })));

  await check('18b. the recipient (non-sender) can mark a message read', () =>
    assertSucceeds(updateDoc(doc(db(vet1), 'interactions/int-accepted/messages/msg-1'), {
      readAt: Timestamp.now(),
    })));

  await check('18c. the sender cannot mark their own message read', () =>
    assertFails(updateDoc(doc(db(farmer1), 'interactions/int-accepted/messages/msg-1'), {
      readAt: Timestamp.now(),
    })));

  await check('18d. marking read cannot also change the message text', () =>
    assertFails(updateDoc(doc(db(vet1), 'interactions/int-accepted/messages/msg-1'), {
      readAt: Timestamp.now(), text: 'tampered',
    })));

  await check('18e. message delete is always rejected', () =>
    assertFails(deleteDoc(doc(db(farmer1), 'interactions/int-accepted/messages/msg-1'))));

  // ── 19-23: users ─────────────────────────────────────────────────────
  console.log('\nusers');

  await check('19. a user can create their own doc with isVerified absent/false', () =>
    assertSucceeds(setDoc(doc(db(shepherd1), 'users/shepherd-1'), {
      uid: 'shepherd-1', phone: '+911111111113', role: 'shepherd', name: 'Shepherd One',
      isProfileComplete: true, preferredLanguage: 'te',
    })));

  await check('20. a user cannot self-grant isVerified: true on create', () =>
    assertFails(setDoc(doc(db(farmer2), 'users/farmer-x'), {
      uid: 'farmer-x', phone: '+911111111199', role: 'farmer', name: 'X',
      isProfileComplete: true, preferredLanguage: 'te', isVerified: true,
    })));

  await check('21. a user cannot flip their own isVerified from false to true on update', () =>
    assertFails(updateDoc(doc(db(vetUnverified), 'users/vet-unverified'), {
      isVerified: true,
    })));

  await check('22. a user can update ordinary profile fields without touching isVerified', () =>
    assertSucceeds(updateDoc(doc(db(farmer1), 'users/farmer-1'), {
      name: 'Farmer One Updated',
    })));

  await check('23. another user cannot read someone else\'s user doc directly', () =>
    assertFails(getDoc(doc(db(shepherd1), 'users/farmer-1'))));

  // ── 24-27: storage ───────────────────────────────────────────────────
  console.log('\nstorage');

  const png1x1 = new Uint8Array([
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
  ]);

  await check('24. a participant can upload an interaction attachment', () =>
    assertSucceeds(uploadBytes(
      ref(storageOf(farmer1), 'interactions/int-accepted/photo1.png'),
      png1x1,
      { contentType: 'image/png' },
    )));

  await check('25. a non-participant cannot upload to that interaction path', () =>
    assertFails(uploadBytes(
      ref(storageOf(shepherd1), 'interactions/int-accepted/photo2.png'),
      png1x1,
      { contentType: 'image/png' },
    )));

  await check('26. a non-participant cannot read an interaction attachment', () =>
    assertFails(getBytes(ref(storageOf(shepherd1), 'interactions/int-accepted/photo1.png'))));

  await check('27. unrelated existing storage paths (farms/*) still behave exactly as before', () =>
    assertSucceeds(uploadBytes(
      ref(storageOf(farmer1), 'farms/farmer-1/farm-1/photo.png'),
      png1x1,
      { contentType: 'image/png' },
    )));

  console.log(`\n${passed} passed, ${failed} failed\n`);
  await testEnv.cleanup();
  if (failed > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
