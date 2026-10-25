import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  confirmed,
  pending,
  cancelled,
  completed,
}

class BookingModel {
  final String bookingId;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final int partySize;
  final String date;
  final String timeSlot;
  final String status;
  final String? appliedOffer;
  final DateTime createdAt;

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.partySize,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.appliedOffer,
    required this.createdAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      bookingId: data['booking_id'] ?? doc.id,
      userId: data['user_id'] ?? '',
      restaurantId: data['restaurant_id'] ?? '',
      restaurantName: data['restaurant_name'] ?? '',
      partySize: data['party_size'] ?? 1,
      date: data['date'] ?? '',
      timeSlot: data['time_slot'] ?? '',
      status: data['status'] ?? 'PENDING',
      appliedOffer: data['applied_offer'],
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'party_size': partySize,
      'date': date,
      'time_slot': timeSlot,
      'status': status,
      'applied_offer': appliedOffer,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  bool get isUpcoming {
    try {
      final bookingDate = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return !bookingDate.isBefore(today) &&
          (status == 'CONFIRMED' || status == 'PENDING');
    } catch (_) {
      return false;
    }
  }

  bool get isPast {
    try {
      final bookingDate = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return bookingDate.isBefore(today) ||
          status == 'COMPLETED' ||
          status == 'CANCELLED';
    } catch (_) {
      return true;
    }
  }

  BookingStatus get bookingStatus {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return BookingStatus.confirmed;
      case 'PENDING':
        return BookingStatus.pending;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'COMPLETED':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }

  BookingModel copyWith({
    String? bookingId,
    String? userId,
    String? restaurantId,
    String? restaurantName,
    int? partySize,
    String? date,
    String? timeSlot,
    String? status,
    String? appliedOffer,
    DateTime? createdAt,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      partySize: partySize ?? this.partySize,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      appliedOffer: appliedOffer ?? this.appliedOffer,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
