import 'package:firebase_auth/firebase_auth.dart';

/// Turns a raw Firebase/Firestore/Storage exception into a message a
/// farmer can actually act on. Land-module screens must never show
/// `error.toString()` directly — that leaks internals like
/// "[cloud_firestore/permission-denied] Missing or insufficient
/// permissions." which explains nothing to a non-technical user.
String friendlyFirebaseMessage(Object error) {
  if (error is FirebaseException) {
    // An oversized upload rejected by storage.rules' 10MB cap surfaces as
    // permission-denied with no dedicated code — the message text is the
    // only signal that distinguishes it from a real permission problem,
    // so this must be checked before the generic permission-denied case
    // below claims it.
    if (error.plugin == 'firebase_storage' && error.code == 'permission-denied') {
      final msg = error.message?.toLowerCase() ?? '';
      if (msg.contains('size') || msg.contains('large')) {
        return 'Image is too large. Please choose a smaller photo.';
      }
    }
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to do that.';
      case 'not-found':
        return 'This land no longer exists. It may have been deleted.';
      case 'unauthenticated':
        return 'Your session has expired. Please sign in again.';
      case 'unavailable':
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'deadline-exceeded':
        return 'The request timed out. Please try again.';
      case 'cancelled': // cloud_firestore spelling
      case 'canceled': // firebase_storage spelling
        return 'Upload cancelled.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';
      case 'object-not-found':
        return 'This photo no longer exists.';
      case 'unauthorized':
        return 'You don\'t have permission to do that.';
      case 'quota-exceeded':
        return 'Storage limit reached. Please contact support.';
    }
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-token-expired':
      case 'user-disabled':
      case 'invalid-user-token':
        return 'Your session has expired. Please sign in again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
