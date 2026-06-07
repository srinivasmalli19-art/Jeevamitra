class UserModel {
  final String id;
  final String name;
  final String phone;
  final String location;
  final String? profilePhoto;
  final bool isVerified;
  final double rating;
  final int totalListings;
  final DateTime memberSince;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    this.profilePhoto,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalListings = 0,
    required this.memberSince,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}
