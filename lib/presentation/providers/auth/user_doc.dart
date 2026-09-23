import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/user_profile_type.dart';

/// Lightweight Firestore user document — used only for auth-level routing.
/// Full profile lives in UserEntity (domain layer).
class UserDoc {
  final String uid;
  final String phone;
  final String role; // 'farmer' | 'shepherd' | 'vet' — unchanged backend value
  final String name;
  final String? village;
  final String? district;
  final bool isProfileComplete;
  final String preferredLanguage;

  /// Admin-granted verification flag for vet accounts. Deliberately never
  /// written by [toMap] — see the comment there.
  final bool isVerified;

  /// The user-facing identity profile chosen on the "Choose Your Profile"
  /// onboarding step (livestockOwner | fodderLandProvider | both), stored
  /// alongside — not instead of — [role] for backward compatibility. Null
  /// for accounts created before this feature existed; [effectiveProfileType]
  /// handles that case without requiring any migration.
  final String? profileType;

  const UserDoc({
    required this.uid,
    required this.phone,
    required this.role,
    required this.name,
    this.village,
    this.district,
    required this.isProfileComplete,
    this.preferredLanguage = 'te',
    this.profileType,
    this.isVerified = false,
  });

  bool get isFarmer => role == 'farmer';
  bool get isShepherd => role == 'shepherd';
  bool get isVet => role == 'vet';

  /// The profile to use for personalization: the explicitly-chosen one if
  /// present, otherwise the best inference from [role] for legacy accounts.
  UserProfileType get effectiveProfileType =>
      UserProfileType.fromStorageValue(profileType) ??
      UserProfileType.inferFromRole(role);

  factory UserDoc.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return UserDoc(
      uid: doc.id,
      phone: d['phone'] as String? ?? '',
      role: d['role'] as String? ?? '',
      name: d['name'] as String? ?? '',
      village: d['village'] as String?,
      district: d['district'] as String?,
      isProfileComplete: d['isProfileComplete'] as bool? ?? false,
      preferredLanguage: d['preferredLanguage'] as String? ?? 'te',
      profileType: d['profileType'] as String?,
      isVerified: d['isVerified'] as bool? ?? false,
    );
  }

  // isVerified is deliberately omitted here. This map is also used by
  // createUserDoc()'s merge:true write on an already-existing doc (e.g. when
  // profile_setup_screen.dart re-runs it), and including isVerified: false
  // there would silently overwrite any admin-granted isVerified: true.
  // Verification must only ever be changed by an admin-side write.
  Map<String, dynamic> toMap() => {
    'uid': uid,
    'phone': phone,
    'role': role,
    'name': name,
    if (village != null) 'village': village,
    if (district != null) 'district': district,
    'isProfileComplete': isProfileComplete,
    'preferredLanguage': preferredLanguage,
    if (profileType != null) 'profileType': profileType,
  };
}
