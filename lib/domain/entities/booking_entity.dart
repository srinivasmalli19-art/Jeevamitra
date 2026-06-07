class BookingEntity {
  final String id;
  final String farmId;
  final String farmTitle;
  final String farmVillage;
  final String farmerId;   // farm owner
  final String shepherdId; // booking requester
  final String shepherdName;
  final int animalCount;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalAmount;
  final double advanceAmount;
  final String status; // pending|confirmed|active|completed|cancelled
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? farmerPhone;
  final String? shepherdPhone;
  final double? reviewRating;
  final String? reviewText;

  const BookingEntity({
    required this.id,
    required this.farmId,
    required this.farmTitle,
    required this.farmVillage,
    required this.farmerId,
    required this.shepherdId,
    required this.shepherdName,
    required this.animalCount,
    required this.checkIn,
    required this.checkOut,
    required this.totalAmount,
    required this.advanceAmount,
    required this.status,
    this.cancellationReason,
    required this.createdAt,
    this.confirmedAt,
    this.farmerPhone,
    this.shepherdPhone,
    this.reviewRating,
    this.reviewText,
  });

  int get durationDays => checkOut.difference(checkIn).inDays;
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canReview => isCompleted && reviewRating == null;
}
