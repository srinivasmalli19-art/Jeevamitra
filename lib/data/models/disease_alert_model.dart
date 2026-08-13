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
    super.village,
    required super.district,
    required super.state,
    required super.lat,
    required super.lng,
    required super.geohash,
    required super.radiusKm,
    super.symptoms,
    super.prevention,
    super.treatment,
    super.vetContactPhone,
    required super.sourceAuthority,
    super.isActive,
    required super.issuedAt,
    super.expiresAt,
    super.reportedBy,
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
      village: d['village'] as String? ?? '',
      district: d['district'] as String? ?? '',
      state: d['state'] as String? ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      geohash: d['geohash'] as String? ?? '',
      radiusKm: (d['radiusKm'] as num?)?.toDouble() ?? 50,
      symptoms: d['symptoms'] as String?,
      prevention: d['prevention'] as String?,
      treatment: d['treatment'] as String?,
      vetContactPhone: d['vetContactPhone'] as String?,
      sourceAuthority: d['sourceAuthority'] as String? ?? '',
      isActive: d['isActive'] as bool? ?? true,
      issuedAt: (d['issuedAt'] as Timestamp).toDate(),
      expiresAt: d['expiresAt'] != null
          ? (d['expiresAt'] as Timestamp).toDate()
          : null,
      reportedBy: d['reportedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'disease': disease,
        'affectedSpecies': affectedSpecies,
        'severity': severity,
        if (village.isNotEmpty) 'village': village,
        'district': district,
        'state': state,
        'lat': lat,
        'lng': lng,
        'geohash': geohash,
        'radiusKm': radiusKm,
        if (symptoms != null) 'symptoms': symptoms,
        if (prevention != null) 'prevention': prevention,
        if (treatment != null) 'treatment': treatment,
        if (vetContactPhone != null) 'vetContactPhone': vetContactPhone,
        'sourceAuthority': sourceAuthority,
        'isActive': isActive,
        'issuedAt': Timestamp.fromDate(issuedAt),
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
        'reportedBy': reportedBy,
      };
}
