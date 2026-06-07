import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/disease_alert_entity.dart';

class DiseaseAlertModel extends DiseaseAlertEntity {
  const DiseaseAlertModel({
    required super.id,
    required super.title,
    required super.description,
    required super.disease,
    required super.affectedSpecies,
    required super.severity,
    required super.district,
    required super.state,
    required super.lat,
    required super.lng,
    required super.geohash,
    required super.radiusKm,
    super.prevention,
    super.treatment,
    super.vetContactPhone,
    required super.sourceAuthority,
    super.isActive,
    required super.issuedAt,
    super.expiresAt,
  });

  factory DiseaseAlertModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DiseaseAlertModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      disease: d['disease'] as String? ?? '',
      affectedSpecies: d['affectedSpecies'] as String? ?? 'all',
      severity: d['severity'] as String? ?? 'low',
      district: d['district'] as String? ?? '',
      state: d['state'] as String? ?? '',
      lat: (d['lat'] as num).toDouble(),
      lng: (d['lng'] as num).toDouble(),
      geohash: d['geohash'] as String? ?? '',
      radiusKm: (d['radiusKm'] as num?)?.toDouble() ?? 50,
      prevention: d['prevention'] as String?,
      treatment: d['treatment'] as String?,
      vetContactPhone: d['vetContactPhone'] as String?,
      sourceAuthority: d['sourceAuthority'] as String? ?? '',
      isActive: d['isActive'] as bool? ?? true,
      issuedAt: (d['issuedAt'] as Timestamp).toDate(),
      expiresAt: d['expiresAt'] != null
          ? (d['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'disease': disease,
        'affectedSpecies': affectedSpecies,
        'severity': severity,
        'district': district,
        'state': state,
        'lat': lat,
        'lng': lng,
        'geohash': geohash,
        'radiusKm': radiusKm,
        if (prevention != null) 'prevention': prevention,
        if (treatment != null) 'treatment': treatment,
        if (vetContactPhone != null) 'vetContactPhone': vetContactPhone,
        'sourceAuthority': sourceAuthority,
        'isActive': isActive,
        'issuedAt': Timestamp.fromDate(issuedAt),
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      };
}
