import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/firebase_error_translator.dart';

void main() {
  group('friendlyFirebaseMessage', () {
    test('permission-denied never exposes the raw Firestore code', () {
      final msg = friendlyFirebaseMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(msg, isNot(contains('permission-denied')));
      expect(msg, isNot(contains('cloud_firestore')));
      expect(msg, "You don't have permission to do that.");
    });

    test('not-found maps to "land no longer exists"', () {
      final msg = friendlyFirebaseMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
      );
      expect(msg, contains('no longer exists'));
    });

    test('unauthenticated maps to session-expired', () {
      final msg = friendlyFirebaseMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'unauthenticated'),
      );
      expect(msg, contains('session has expired'));
    });

    test('FirebaseAuthException token-expired also maps to session-expired', () {
      final msg = friendlyFirebaseMessage(
        FirebaseAuthException(code: 'user-token-expired'),
      );
      expect(msg, contains('session has expired'));
    });

    test('network-request-failed / unavailable map to a connectivity message', () {
      expect(
        friendlyFirebaseMessage(
            FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')),
        contains('No internet connection'),
      );
      expect(
        friendlyFirebaseMessage(FirebaseException(
            plugin: 'cloud_firestore', code: 'network-request-failed')),
        contains('No internet connection'),
      );
    });

    test('storage cancellation maps to "Upload cancelled"', () {
      final msg = friendlyFirebaseMessage(
        FirebaseException(plugin: 'firebase_storage', code: 'canceled'),
      );
      expect(msg, 'Upload cancelled.');
    });

    test('an oversized-upload rejection is recognized from its message text', () {
      final msg = friendlyFirebaseMessage(
        FirebaseException(
          plugin: 'firebase_storage',
          code: 'permission-denied',
          message: 'File size exceeds the maximum allowed size.',
        ),
      );
      expect(msg, contains('too large'));
    });

    test('an unrecognized error never leaks its raw toString()', () {
      final msg = friendlyFirebaseMessage(Exception('some internal detail'));
      expect(msg, isNot(contains('some internal detail')));
      expect(msg, 'Something went wrong. Please try again.');
    });
  });
}
