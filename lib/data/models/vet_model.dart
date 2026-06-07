import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/vet_entity.dart';

class VetModel extends VetEntity {
  const VetModel({
    required super.id,
    required super.name,
    required super.qualification,
    required super.specialization,
    required super.phone,
    super.whatsapp,
    required super.village,
    required super.district,
    required super.state,
    required super.lat,
    required super.lng,
    required super.geohash,
    super.services,
    super.isGovtVet,
    super.isAvailable24x7,
    super.consultationFee,
    super.rating,
    super.reviewCount,
    super.profileImageUrl,
    super.isVerified,
  });

  factory VetModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return VetModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      qualification: d['qualification'] as String? ?? '',
      specialization: d['specialization'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      whatsapp: d['whatsapp'] as String?,
      village: d['village'] as String? ?? '',
      district: d['district'] as String? ?? '',
      state: d['state'] as String? ?? '',
      lat: (d['lat'] as num).toDouble(),
      lng: (d['lng'] as num).toDouble(),
      geohash: d['geohash'] as String? ?? '',
      services: List<String>.from(d['services'] as List? ?? []),
      isGovtVet: d['isGovtVet'] as bool? ?? false,
      isAvailable24x7: d['isAvailable24x7'] as bool? ?? false,
      consultationFee: (d['consultationFee'] as num?)?.toDouble(),
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      profileImageUrl: d['profileImageUrl'] as String?,
      isVerified: d['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'qualification': qualification,
        'specialization': specialization,
        'phone': phone,
        if (whatsapp != null) 'whatsapp': whatsapp,
        'village': village,
        'district': district,
        'state': state,
        'lat': lat,
        'lng': lng,
        'geohash': geohash,
        'services': services,
        'isGovtVet': isGovtVet,
        'isAvailable24x7': isAvailable24x7,
        if (consultationFee != null) 'consultationFee': consultationFee,
        'rating': rating,
        'reviewCount': reviewCount,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'isVerified': isVerified,
      };
}
