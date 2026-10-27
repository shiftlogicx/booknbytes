import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  rejected('REJECTED'),
  cancelled('CANCELLED'),
  completed('COMPLETED'),
  noShow('NO_SHOW');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromString(String status) {
    final clean = status.toUpperCase().replaceAll('-', '_');
    return BookingStatus.values.firstWhere(
      (e) => e.value == clean,
      orElse: () => BookingStatus.pending,
    );
  }
}

class BookingModel {
  final String bookingId;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final int partySize;
  final String date;
  final String timeSlot;
  final BookingStatus status;
  final String? appliedOffer;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final String? specialRequests;

  const BookingModel({
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
    this.customerName,
    this.customerPhone,
    this.specialRequests,
  });

  bool get isPending => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isRejected => status == BookingStatus.rejected;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isNoShow => status == BookingStatus.noShow;

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel.fromMap(data);
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['created_at'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return BookingModel(
      bookingId: map['booking_id'] ?? '',
      userId: map['user_id'] ?? '',
      restaurantId: map['restaurant_id'] ?? '',
      restaurantName: map['restaurant_name'] ?? '',
      partySize: (map['party_size'] ?? 1).toInt(),
      date: map['date'] ?? '',
      timeSlot: map['time_slot'] ?? '',
      status: BookingStatus.fromString(map['status'] ?? 'PENDING'),
      appliedOffer: map['applied_offer'],
      createdAt: parsedCreatedAt,
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      specialRequests: map['special_requests'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'party_size': partySize,
      'date': date,
      'time_slot': timeSlot,
      'status': status.value,
      'applied_offer': appliedOffer,
      'created_at': createdAt.toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'special_requests': specialRequests,
    };
  }

  BookingModel copyWith({
    String? bookingId,
    String? userId,
    String? restaurantId,
    String? restaurantName,
    int? partySize,
    String? date,
    String? timeSlot,
    BookingStatus? status,
    String? appliedOffer,
    DateTime? createdAt,
    String? customerName,
    String? customerPhone,
    String? specialRequests,
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
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      specialRequests: specialRequests ?? this.specialRequests,
    );
  }
}
