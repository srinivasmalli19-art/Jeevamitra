import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight Firestore user document — used only for auth-level routing.
/// Full profile lives in UserEntity (domain layer).
class UserDoc {
  final String uid;
  final String phone;
  final String role; // 'farmer' | 'shepherd'
  final String name;
  final String? village;
  final String? district;
  final bool isProfileComplete;
  final String preferredLanguage;

  const UserDoc({
    required this.uid,
    required this.phone,
    required this.role,
    required this.name,
    this.village,
    this.district,
    required this.isProfileComplete,
    this.preferredLanguage = 'te',
  });

  bool get isFarmer => role == 'farmer';
  bool get isShepherd => role == 'shepherd';

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
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'phone': phone,
    'role': role,
    'name': name,
    if (village != null) 'village': village,
    if (district != null) 'district': district,
    'isProfileComplete': isProfileComplete,
    'preferredLanguage': preferredLanguage,
  };
}
