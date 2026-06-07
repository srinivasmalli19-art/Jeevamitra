import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.farmId,
    required super.farmTitle,
    required super.farmVillage,
    required super.farmerId,
    required super.shepherdId,
    required super.shepherdName,
    required super.animalCount,
    required super.checkIn,
    required super.checkOut,
    required super.totalAmount,
    required super.advanceAmount,
    required super.status,
    super.cancellationReason,
    required super.createdAt,
    super.confirmedAt,
    super.farmerPhone,
    super.shepherdPhone,
    super.reviewRating,
    super.reviewText,
  });

  factory BookingModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BookingModel(
      id: doc.id,
      farmId: d['farmId'] as String,
      farmTitle: d['farmTitle'] as String? ?? '',
      farmVillage: d['farmVillage'] as String? ?? '',
      farmerId: d['farmerId'] as String,
      shepherdId: d['shepherdId'] as String,
      shepherdName: d['shepherdName'] as String? ?? '',
      animalCount: (d['animalCount'] as num).toInt(),
      checkIn: (d['checkIn'] as Timestamp).toDate(),
      checkOut: (d['checkOut'] as Timestamp).toDate(),
      totalAmount: (d['totalAmount'] as num).toDouble(),
      advanceAmount: (d['advanceAmount'] as num?)?.toDouble() ?? 0,
      status: d['status'] as String? ?? 'pending',
      cancellationReason: d['cancellationReason'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      confirmedAt: d['confirmedAt'] != null
          ? (d['confirmedAt'] as Timestamp).toDate()
          : null,
      farmerPhone: d['farmerPhone'] as String?,
      shepherdPhone: d['shepherdPhone'] as String?,
      reviewRating: (d['reviewRating'] as num?)?.toDouble(),
      reviewText: d['reviewText'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'farmId': farmId,
        'farmTitle': farmTitle,
        'farmVillage': farmVillage,
        'farmerId': farmerId,
        'shepherdId': shepherdId,
        'shepherdName': shepherdName,
        'animalCount': animalCount,
        'checkIn': Timestamp.fromDate(checkIn),
        'checkOut': Timestamp.fromDate(checkOut),
        'totalAmount': totalAmount,
        'advanceAmount': advanceAmount,
        'status': status,
        if (cancellationReason != null) 'cancellationReason': cancellationReason,
        'createdAt': Timestamp.fromDate(createdAt),
        if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
        if (farmerPhone != null) 'farmerPhone': farmerPhone,
        if (shepherdPhone != null) 'shepherdPhone': shepherdPhone,
        if (reviewRating != null) 'reviewRating': reviewRating,
        if (reviewText != null) 'reviewText': reviewText,
      };

  BookingModel copyWithModel({
    String? status,
    String? cancellationReason,
    DateTime? confirmedAt,
    double? reviewRating,
    String? reviewText,
  }) =>
      BookingModel(
        id: id,
        farmId: farmId,
        farmTitle: farmTitle,
        farmVillage: farmVillage,
        farmerId: farmerId,
        shepherdId: shepherdId,
        shepherdName: shepherdName,
        animalCount: animalCount,
        checkIn: checkIn,
        checkOut: checkOut,
        totalAmount: totalAmount,
        advanceAmount: advanceAmount,
        status: status ?? this.status,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        createdAt: createdAt,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        farmerPhone: farmerPhone,
        shepherdPhone: shepherdPhone,
        reviewRating: reviewRating ?? this.reviewRating,
        reviewText: reviewText ?? this.reviewText,
      );
}
