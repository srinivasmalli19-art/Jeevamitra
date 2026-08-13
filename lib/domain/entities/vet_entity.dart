class VetEntity {
  final String id;
  final String name;
  final String qualification;
  final String specialization;
  final String phone;
  final String? whatsapp;
  final String village;
  final String district;
  final String state;
  final double lat;
  final double lng;
  final String geohash;
  final List<String> services;
  final bool isGovtVet;
  final bool isAvailable24x7;
  final double? consultationFee;
  final double rating;
  final int reviewCount;
  final String? profileImageUrl;
  final bool isVerified;
  final int yearsOfExperience;
  final List<String> languages;
  final List<String> galleryUrls;

  const VetEntity({
    required this.id,
    required this.name,
    required this.qualification,
    required this.specialization,
    required this.phone,
    this.whatsapp,
    required this.village,
    required this.district,
    required this.state,
    required this.lat,
    required this.lng,
    required this.geohash,
    this.services = const [],
    this.isGovtVet = false,
    this.isAvailable24x7 = false,
    this.consultationFee,
    this.rating = 0,
    this.reviewCount = 0,
    this.profileImageUrl,
    this.isVerified = false,
    this.yearsOfExperience = 0,
    this.languages = const [],
    this.galleryUrls = const [],
  });

  bool get isFree => consultationFee == null || consultationFee == 0;
}
