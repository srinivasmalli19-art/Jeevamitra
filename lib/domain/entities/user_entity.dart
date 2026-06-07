class UserEntity {
  final String uid;
  final String phone;
  final String role; // 'farmer' | 'shepherd'
  final String name;
  final String? village;
  final String? district;
  final String? state;
  final String? profileImageUrl;
  final bool isProfileComplete;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final String preferredLanguage;

  const UserEntity({
    required this.uid,
    required this.phone,
    required this.role,
    required this.name,
    this.village,
    this.district,
    this.state,
    this.profileImageUrl,
    required this.isProfileComplete,
    this.isVerified = false,
    required this.createdAt,
    this.lastActiveAt,
    this.preferredLanguage = 'te',
  });

  bool get isFarmer => role == 'farmer';
  bool get isShepherd => role == 'shepherd';

  UserEntity copyWith({
    String? name,
    String? village,
    String? district,
    String? state,
    String? profileImageUrl,
    bool? isProfileComplete,
    bool? isVerified,
    DateTime? lastActiveAt,
    String? preferredLanguage,
  }) {
    return UserEntity(
      uid: uid,
      phone: phone,
      role: role,
      name: name ?? this.name,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
