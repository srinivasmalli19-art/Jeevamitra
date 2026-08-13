class DiseaseAlertEntity {
  final String id;
  final String title;
  final String description;
  final String disease;
  final String affectedSpecies; // 'sheep'|'goat'|'cattle'|'all'
  final String severity; // 'low'|'medium'|'high'|'critical'
  final String village;
  final String district;
  final String state;
  final double lat;
  final double lng;
  final String geohash;
  final double radiusKm;
  final String? symptoms;
  final String? prevention;
  final String? treatment;
  final String? vetContactPhone;
  final String sourceAuthority;
  final bool isActive;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  // Who reported this alert (uid). Required by firestore.rules' update/delete
  // check (`resource.data.reportedBy`) — without it, deactivating an alert
  // is permission-denied for every user, including its own reporter.
  final String reportedBy;

  const DiseaseAlertEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.disease,
    required this.affectedSpecies,
    required this.severity,
    this.village = '',
    required this.district,
    required this.state,
    required this.lat,
    required this.lng,
    required this.geohash,
    required this.radiusKm,
    this.symptoms,
    this.prevention,
    this.treatment,
    this.vetContactPhone,
    required this.sourceAuthority,
    this.isActive = true,
    required this.issuedAt,
    this.expiresAt,
    this.reportedBy = '',
  });

  bool get isCritical => severity == 'critical';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}
