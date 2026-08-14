// Regression coverage for the OTP silent-failure bug fixed in
// lib/presentation/providers/auth/auth_provider.dart: sendOtp() used to
// return before codeSent/verificationFailed ever fired, so callers always
// saw `error == null` even when Firebase had already rejected the request.
// These tests mock FirebaseAuth.verifyPhoneNumber and manually invoke each
// terminal callback to prove sendOtp() now waits for the real outcome.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/presentation/providers/auth/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUserMetadata extends Mock implements UserMetadata {}

/// A [MockUser] whose `metadata.lastSignInTime` looks recent enough to pass
/// deleteAccount()'s proactive requires-recent-login pre-check.
MockUser _freshlySignedInUser() {
  final user = MockUser();
  final metadata = MockUserMetadata();
  when(() => metadata.lastSignInTime).thenReturn(DateTime.now());
  when(() => user.metadata).thenReturn(metadata);
  return user;
}

class FakePhoneAuthCredential extends Fake implements PhoneAuthCredential {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePhoneAuthCredential());
    registerFallbackValue(Duration.zero);
  });

  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late AuthNotifier notifier;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    notifier = AuthNotifier(auth: mockAuth, firestore: fakeFirestore);
  });

  group('sendOtp — real outcome propagation (the OTP bug fix)', () {
    test('returns null and captures the verification id when codeSent fires', () async {
      when(() => mockAuth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            timeout: any(named: 'timeout'),
            forceResendingToken: any(named: 'forceResendingToken'),
          )).thenAnswer((invocation) async {
        final codeSent = invocation.namedArguments[#codeSent]
            as void Function(String, int?);
        codeSent('test-verification-id', 42);
      });

      final error = await notifier.sendOtp('+919876543210');

      expect(error, isNull);
      expect(notifier.debugVerificationId, 'test-verification-id');
    });

    test(
        'returns the real error message when verificationFailed fires — '
        'this is the exact scenario that used to be swallowed silently',
        () async {
      when(() => mockAuth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            timeout: any(named: 'timeout'),
            forceResendingToken: any(named: 'forceResendingToken'),
          )).thenAnswer((invocation) async {
        final verificationFailed = invocation.namedArguments[#verificationFailed]
            as void Function(FirebaseAuthException);
        verificationFailed(FirebaseAuthException(
          code: 'app-not-authorized',
          message: 'Play Integrity attestation failed — check SHA fingerprints.',
        ));
      });

      final error = await notifier.sendOtp('+919876543210');

      expect(error, 'Play Integrity attestation failed — check SHA fingerprints.');
      expect(notifier.debugVerificationId, isNull,
          reason: 'a failed verification must not leave a stale verification id behind');
    });

    test('falls back to a generic message when the exception has no message', () async {
      when(() => mockAuth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            timeout: any(named: 'timeout'),
            forceResendingToken: any(named: 'forceResendingToken'),
          )).thenAnswer((invocation) async {
        final verificationFailed = invocation.namedArguments[#verificationFailed]
            as void Function(FirebaseAuthException);
        verificationFailed(FirebaseAuthException(code: 'quota-exceeded'));
      });

      final error = await notifier.sendOtp('+919876543210');
      expect(error, 'Verification failed. Please try again.');
    });

    test('auto-verification (verificationCompleted) signs in and returns null', () async {
      final credential = FakePhoneAuthCredential();
      final userCredential = MockUserCredential();
      when(() => mockAuth.signInWithCredential(any()))
          .thenAnswer((_) async => userCredential);

      when(() => mockAuth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            timeout: any(named: 'timeout'),
            forceResendingToken: any(named: 'forceResendingToken'),
          )).thenAnswer((invocation) async {
        final verificationCompleted = invocation.namedArguments[#verificationCompleted]
            as void Function(PhoneAuthCredential);
        verificationCompleted(credential);
      });

      final error = await notifier.sendOtp('+919876543210');

      expect(error, isNull);
      verify(() => mockAuth.signInWithCredential(credential)).called(1);
    });

    test('a thrown platform exception from verifyPhoneNumber itself is reported, not swallowed',
        () async {
      when(() => mockAuth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            timeout: any(named: 'timeout'),
            forceResendingToken: any(named: 'forceResendingToken'),
          )).thenThrow(
        FirebaseAuthException(code: 'network-request-failed', message: 'No internet connection.'),
      );

      final error = await notifier.sendOtp('+919876543210');
      expect(error, 'No internet connection.');
    });
  });

  group('verifyOtp', () {
    test('returns false without calling Firebase when no verification id is set', () async {
      final ok = await notifier.verifyOtp('123456');
      expect(ok, isFalse);
      verifyNever(() => mockAuth.signInWithCredential(any()));
    });

    test('signs in and returns true once a verification id has been captured', () async {
      // Seed a verification id the same way codeSent would.
      when(() => mockAuth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            timeout: any(named: 'timeout'),
            forceResendingToken: any(named: 'forceResendingToken'),
          )).thenAnswer((invocation) async {
        final codeSent = invocation.namedArguments[#codeSent]
            as void Function(String, int?);
        codeSent('vid-123', null);
      });
      await notifier.sendOtp('+919876543210');

      final userCredential = MockUserCredential();
      when(() => mockAuth.signInWithCredential(any()))
          .thenAnswer((_) async => userCredential);

      final ok = await notifier.verifyOtp('654321');
      expect(ok, isTrue);
    });

    test('returns false when Firebase rejects the OTP code', () async {
      when(() => mockAuth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            timeout: any(named: 'timeout'),
            forceResendingToken: any(named: 'forceResendingToken'),
          )).thenAnswer((invocation) async {
        final codeSent = invocation.namedArguments[#codeSent]
            as void Function(String, int?);
        codeSent('vid-123', null);
      });
      await notifier.sendOtp('+919876543210');

      when(() => mockAuth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'invalid-verification-code'),
      );

      final ok = await notifier.verifyOtp('000000');
      expect(ok, isFalse);
    });
  });

  group('createUserDoc / updateProfile (Firestore write path)', () {
    test('createUserDoc writes a merged doc under users/{uid}', () async {
      final ok = await notifier.createUserDoc(
        uid: 'uid-1',
        phone: '+919876543210',
        role: 'farmer',
        name: 'Ravi',
        village: 'Narasaraopet',
        district: 'Guntur',
      );

      expect(ok, isTrue);
      final doc = await fakeFirestore.collection('users').doc('uid-1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['name'], 'Ravi');
      expect(doc.data()!['isProfileComplete'], isTrue);
    });

    test('createUserDoc marks profile incomplete when village/district are missing', () async {
      await notifier.createUserDoc(
        uid: 'uid-2',
        phone: '+919876543210',
        role: 'shepherd',
        name: 'Suresh',
      );
      final doc = await fakeFirestore.collection('users').doc('uid-2').get();
      expect(doc.data()!['isProfileComplete'], isFalse);
    });

    test('updateProfile updates the existing fields', () async {
      await fakeFirestore.collection('users').doc('uid-3').set({'name': 'Old'});
      final ok = await notifier.updateProfile(
        uid: 'uid-3',
        name: 'New Name',
        village: 'Vijayawada',
        district: 'Krishna',
        preferredLanguage: 'en',
      );
      expect(ok, isTrue);
      final doc = await fakeFirestore.collection('users').doc('uid-3').get();
      expect(doc.data()!['name'], 'New Name');
      expect(doc.data()!['village'], 'Vijayawada');
    });
  });

  group('deleteAccount', () {
    test('deletes the Firestore doc and the auth account on full success', () async {
      await fakeFirestore.collection('users').doc('uid-del').set({'name': 'Gone Soon'});
      final mockUser = _freshlySignedInUser();
      when(() => mockUser.delete()).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final result = await notifier.deleteAccount('uid-del');

      expect(result, isNull);
      final doc = await fakeFirestore.collection('users').doc('uid-del').get();
      expect(doc.exists, isFalse);
      verify(() => mockUser.delete()).called(1);
      expect(notifier.state, isA<AsyncData<void>>());
    });

    test(
        'stale session -> refuses up front and never touches Firestore or '
        'calls Auth.delete()', () async {
      await fakeFirestore.collection('users').doc('uid-stale').set({'name': 'Still Here'});
      final mockUser = MockUser();
      final metadata = MockUserMetadata();
      when(() => metadata.lastSignInTime)
          .thenReturn(DateTime.now().subtract(const Duration(minutes: 30)));
      when(() => mockUser.metadata).thenReturn(metadata);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final result = await notifier.deleteAccount('uid-stale');

      expect(result, contains('sign in again'));
      // Nothing was deleted — the whole point of the proactive check.
      final doc = await fakeFirestore.collection('users').doc('uid-stale').get();
      expect(doc.exists, isTrue);
      verifyNever(() => mockUser.delete());
      expect(notifier.state, isA<AsyncData<void>>());
    });

    test(
        'reactive requires-recent-login (fresh session, but Firebase '
        'disagrees) -> reports it explicitly instead of hiding the '
        'half-finished deletion, and does not claim success', () async {
      await fakeFirestore.collection('users').doc('uid-del2').set({'name': 'X'});
      final mockUser = _freshlySignedInUser();
      when(() => mockUser.delete())
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final result = await notifier.deleteAccount('uid-del2');

      expect(result, isNotNull);
      expect(result, contains('sign in again'));
      // Firestore doc must already be gone even though the auth delete failed
      // (documented, unavoidable trade-off — the reactive fallback path).
      final doc = await fakeFirestore.collection('users').doc('uid-del2').get();
      expect(doc.exists, isFalse);
      expect(notifier.state, isA<AsyncError<void>>());
    });

    test(
        'generic Auth deletion failure -> reports failure, never reports '
        'success, and never signs the user out as if it worked', () async {
      await fakeFirestore.collection('users').doc('uid-del3').set({'name': 'Y'});
      final mockUser = _freshlySignedInUser();
      when(() => mockUser.delete())
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final result = await notifier.deleteAccount('uid-del3');

      expect(result, isNotNull);
      expect(result, isNot(contains('sign in again')));
      expect(notifier.state, isA<AsyncError<void>>());
      // deleteAccount() never itself calls signOut() — a failed deletion
      // must not look like a completed one to the caller.
      verifyNever(() => mockAuth.signOut());
    });
  });

  group('signOut', () {
    test('calls FirebaseAuth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      await notifier.signOut();
      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
