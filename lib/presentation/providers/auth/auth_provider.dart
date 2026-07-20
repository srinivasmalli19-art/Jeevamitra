import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/utils/otp_flow_logger.dart';
import 'user_doc.dart';

// ─── Firebase auth state stream ───────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    otpFlowLog(
      'Auth state changed — user=${user == null ? 'null (signed out)' : user.uid}',
    );
    return user;
  });
});

// ─── Firestore user doc stream ────────────────────────────────────────────────

final currentUserDocProvider = StreamProvider<UserDoc?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection(FirebaseConstants.users)
          .doc(user.uid)
          .withConverter<UserDoc?>(
            fromFirestore: (snap, _) =>
                snap.exists ? UserDoc.fromFirestore(snap) : null,
            toFirestore: (doc, _) => doc?.toMap() ?? {},
          )
          .snapshots()
          .map((snap) => snap.data());
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ─── Auth notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const AsyncValue.data(null));

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? _verificationId;
  int? _resendToken;

  /// Exposed for tests that need to assert on the verification id a
  /// `codeSent`/`codeAutoRetrievalTimeout` callback captured.
  String? get debugVerificationId => _verificationId;

  /// Sends (or resends) an OTP to [phone] and reports the real outcome.
  ///
  /// `FirebaseAuth.verifyPhoneNumber()`'s returned Future completes as soon
  /// as the native call has registered its event-channel listener — well
  /// before `codeSent`/`verificationFailed` actually fire (those arrive
  /// later on that event channel). Awaiting it directly and returning
  /// whatever a callback happened to set by then is a race: the caller
  /// almost always got `null` (no error) and navigated to the OTP screen
  /// even when verification had already failed (bad phone number, quota
  /// exceeded, missing SHA-1/SHA-256 in Firebase causing a Play Integrity
  /// attestation failure, etc.), leaving the user stuck with no error and
  /// no OTP. A [Completer] makes this method actually wait for one of the
  /// terminal callbacks before returning.
  Future<String?> sendOtp(String phone) async {
    otpFlowLog('sendOtp() entered — phone=$phone');
    state = const AsyncValue.loading();
    final completer = Completer<String?>();

    void complete(String? error) {
      if (!completer.isCompleted) {
        otpFlowLog('Completer completed — error=$error');
        completer.complete(error);
      }
    }

    try {
      otpFlowLog('verifyPhoneNumber() invoked — phone=$phone');
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          otpFlowLog('verificationCompleted callback fired');
          try {
            await _auth.signInWithCredential(credential);
            state = const AsyncValue.data(null);
          } catch (e, st) {
            state = AsyncValue.error(e, st);
          }
          complete(null);
        },
        verificationFailed: (FirebaseAuthException e) {
          otpFlowLog(
            'verificationFailed callback fired — '
            'code=${e.code}, message=${e.message}',
          );
          state = AsyncValue.error(e, StackTrace.current);
          complete(e.message ?? 'Verification failed. Please try again.');
        },
        codeSent: (String verificationId, int? resendToken) {
          otpFlowLog(
            'codeSent callback fired — '
            'verificationId=$verificationId, resendToken=$resendToken',
          );
          _verificationId = verificationId;
          _resendToken = resendToken;
          state = const AsyncValue.data(null);
          complete(null);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          otpFlowLog(
            'codeAutoRetrievalTimeout callback fired — '
            'verificationId=$verificationId',
          );
          // Auto SMS-read gave up; the code was still sent, so keep the
          // verification id usable for manual entry. Only completes the
          // request here if codeSent never fired for some reason.
          _verificationId = verificationId;
          complete(null);
        },
      );
    } catch (e, st) {
      otpFlowLog(
        'verifyPhoneNumber() threw synchronously — '
        '${e is FirebaseAuthException ? 'code=${e.code}, message=${e.message}' : 'error=$e'}',
      );
      state = AsyncValue.error(e, st);
      complete(
        e is FirebaseAuthException
            ? (e.message ?? 'Verification failed. Please try again.')
            : 'Could not send OTP. Check your connection and try again.',
      );
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 65),
      onTimeout: () {
        otpFlowLog('Completer timed out after 65s with no callback firing');
        return 'Request timed out. Please try again.';
      },
    );
    otpFlowLog('sendOtp() returned — value=$result');
    return result;
  }

  Future<bool> verifyOtp(String otp) async {
    if (_verificationId == null) return false;
    state = const AsyncValue.loading();
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Returns true on success. Also used for the initial partial doc written
  /// right after role selection, where [village]/[district] are still null.
  Future<bool> createUserDoc({
    required String uid,
    required String phone,
    required String role,
    required String name,
    String? village,
    String? district,
    String preferredLanguage = 'te',
  }) async {
    state = const AsyncValue.loading();
    try {
      final doc = UserDoc(
        uid: uid,
        phone: phone,
        role: role,
        name: name,
        village: village,
        district: district,
        isProfileComplete: name.isNotEmpty && village != null && district != null,
        preferredLanguage: preferredLanguage,
      );
      await _firestore
          .collection(FirebaseConstants.users)
          .doc(uid)
          .set(doc.toMap(), SetOptions(merge: true));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String uid,
    required String name,
    required String village,
    required String district,
    required String preferredLanguage,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _firestore
          .collection(FirebaseConstants.users)
          .doc(uid)
          .update({
        'name': name,
        'village': village,
        'district': district,
        'preferredLanguage': preferredLanguage,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Deletes the user's Firestore document, then their Firebase Auth account.
  ///
  /// Returns null on full success, or a user-facing message describing what
  /// happened. There is no server (no Cloud Functions in this project), so
  /// the two deletes cannot be made atomic from the client: the Firestore
  /// delete must happen first, while the session is still valid enough for
  /// Firestore's security rules to authorize it. If the account delete then
  /// fails afterwards (most commonly `requires-recent-login`), the user's
  /// data is already gone but their Auth account still exists — rather than
  /// hiding that, we say so explicitly so they know exactly what to do next.
  Future<String?> deleteAccount(String uid) async {
    state = const AsyncValue.loading();

    try {
      await _firestore
          .collection(FirebaseConstants.users)
          .doc(uid)
          .delete();
    } catch (e, st) {
      // Nothing was removed — safe to retry from scratch.
      state = AsyncValue.error(e, st);
      return 'Could not delete your data. Please check your connection and try again.';
    }

    try {
      await _auth.currentUser?.delete();
      state = const AsyncValue.data(null);
      return null;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e, st);
      if (e.code == 'requires-recent-login') {
        return 'Your data was deleted. For security, please sign in again and delete your account once more to finish removing it.';
      }
      return 'Your data was deleted, but we could not remove your sign-in. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (_) => AuthNotifier(),
);
