import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_profile_type.dart';

/// Holds the profile chosen on the new pre-auth "Choose Your Profile" step
/// until OTP verification succeeds and it can be written to the user's
/// Firestore doc (there is no authenticated uid to write to before then).
/// Deliberately in-memory only, not persisted to disk: if the app is killed
/// mid-onboarding the user simply re-enters their choice, which is
/// acceptable for an incomplete signup and avoids adding any new storage.
final pendingProfileTypeProvider = StateProvider<UserProfileType?>((ref) => null);
