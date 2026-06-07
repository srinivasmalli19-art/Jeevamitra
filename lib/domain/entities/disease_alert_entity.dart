class DiseaseAlertEntity {
  final String id;
  final String title;
  final String description;
  final String disease;
  final String affectedSpecies; // 'sheep'|'goat'|'cattle'|'all'
  final String severity; // 'low'|'medium'|'high'|'critical'
  final String district;
  final String state;
  final double lat;
  final double lng;
  final String geohash;
  final double radiusKm;
  final String? prevention;
  final String? treatment;
  final String? vetContactPhone;
  final String sourceAuthority;
  final bool isActive;
  final DateTime issuedAt;
  final DateTime? expiresAt;

  const DiseaseAlertEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.disease,
    required this.affectedSpecies,
    required this.severity,
    required this.district,
    required this.state,
    required this.lat,
    required this.lng,
    required this.geohash,
    required this.radiusKm,
    this.prevention,
    this.treatment,
    this.vetContactPhone,
    required this.sourceAuthority,
    this.isActive = true,
    required this.issuedAt,
    this.expiresAt,
  });

  bool get isCritical => severity == 'critical';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}
