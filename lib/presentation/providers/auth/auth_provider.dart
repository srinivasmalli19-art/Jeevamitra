import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firebase_constants.dart';
import 'user_doc.dart';

// ─── Firebase auth state stream ───────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
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
  AuthNotifier() : super(const AsyncValue.data(null));

  String? _verificationId;
  int? _resendToken;

  Future<String?> sendOtp(String phone) async {
    state = const AsyncValue.loading();
    String? error;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        error = e.message ?? 'Verification failed';
        state = AsyncValue.error(e, StackTrace.current);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        state = const AsyncValue.data(null);
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return error;
  }

  Future<bool> verifyOtp(String otp) async {
    if (_verificationId == null) return false;
    state = const AsyncValue.loading();
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
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
      await FirebaseFirestore.instance
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
      await FirebaseFirestore.instance
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
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.users)
          .doc(uid)
          .delete();
    } catch (e, st) {
      // Nothing was removed — safe to retry from scratch.
      state = AsyncValue.error(e, st);
      return 'Could not delete your data. Please check your connection and try again.';
    }

    try {
      await FirebaseAuth.instance.currentUser?.delete();
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
    await FirebaseAuth.instance.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (_) => AuthNotifier(),
);
