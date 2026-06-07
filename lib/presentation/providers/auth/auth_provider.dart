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

  Future<void> createUserDoc({
    required String uid,
    required String phone,
    required String role,
    required String name,
    String? village,
    String preferredLanguage = 'te',
  }) async {
    final doc = UserDoc(
      uid: uid,
      phone: phone,
      role: role,
      name: name,
      village: village,
      isProfileComplete: name.isNotEmpty && village != null,
      preferredLanguage: preferredLanguage,
    );
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.users)
        .doc(uid)
        .set(doc.toMap(), SetOptions(merge: true));
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

  Future<bool> deleteAccount(String uid) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.users)
          .doc(uid)
          .delete();
      await FirebaseAuth.instance.currentUser?.delete();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> devSignIn({String role = 'farmer'}) async {
    state = const AsyncValue.loading();
    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      final uid = result.user!.uid;
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.users)
          .doc(uid)
          .set({
        'uid': uid,
        'phone': '+91 0000000000',
        'role': role,
        'name': 'Test ${role == 'farmer' ? 'Farmer' : 'Shepherd'}',
        'village': 'Test Village',
        'district': 'Hyderabad',
        'isProfileComplete': true,
        'preferredLanguage': 'te',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (_) => AuthNotifier(),
);
