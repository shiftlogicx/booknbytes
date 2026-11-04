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
  final String? paymentId;
  final String? slotId;
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
    this.paymentId,
    this.slotId,
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

  /// Parse the scheduled date and time into a DateTime object.
  DateTime? get scheduledDateTime {
    try {
      if (date.isEmpty) return null;
      final dateClean = date.split('T')[0].trim();
      final dateParts = dateClean.split('-');
      if (dateParts.length < 3) return null;
      final y = int.parse(dateParts[0]);
      final m = int.parse(dateParts[1]);
      final d = int.parse(dateParts[2]);

      int hour = 12;
      int minute = 0;
      final cleanSlot = timeSlot.trim().toUpperCase();
      final isPM = cleanSlot.contains('PM');
      final isAM = cleanSlot.contains('AM');
      final slotWithoutPeriod = cleanSlot.replaceAll('AM', '').replaceAll('PM', '').trim();
      final timeParts = slotWithoutPeriod.split(':');
      if (timeParts.isNotEmpty) {
        hour = int.tryParse(timeParts[0].trim()) ?? 12;
        if (timeParts.length > 1) {
          minute = int.tryParse(timeParts[1].trim()) ?? 0;
        }
        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
      }
      return DateTime(y, m, d, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Whether this booking is for today (same local calendar date).
  bool get isForToday {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final bookingDateClean = date.split('T')[0].trim();
    return bookingDateClean == todayStr;
  }

  /// Whether this booking is for current or upcoming time for the same day.
  /// Past bookings (either past dates or time slots already passed today) return false.
  bool get isCurrentOrUpcomingForToday {
    if (!isForToday) return false;
    final scheduled = scheduledDateTime;
    if (scheduled == null) return true;

    final now = DateTime.now();
    // Allow up to a 10-minute grace window for "current time" reservations
    return scheduled.isAfter(now.subtract(const Duration(minutes: 10)));
  }

  factory BookingModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel.fromMap(data);
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['created_at'];
    if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    // Resolve customer info: can come directly, or via joined users table
    String? resolvedName = map['customer_name'] ?? map['name'] ?? map['user_name'];
    String? resolvedPhone = map['customer_phone'] ?? map['phone'] ?? map['phone_number'];
    if ((resolvedName == null || resolvedName.trim().isEmpty || resolvedName == 'Guest Diner') && map['users'] is Map<String, dynamic>) {
      final userMap = map['users'] as Map<String, dynamic>;
      resolvedName = userMap['name'] ?? resolvedName;
      resolvedPhone = userMap['phone_number'] ?? resolvedPhone;
    }

    return BookingModel(
      bookingId: map['booking_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      restaurantId: map['restaurant_id']?.toString() ?? '',
      restaurantName: map['restaurant_name']?.toString() ?? 'BookNBytes Restaurant',
      partySize: (map['party_size'] as num?)?.toInt() ?? 2,
      date: map['booking_date']?.toString() ?? map['date']?.toString() ?? '',
      timeSlot: map['time_slot']?.toString() ?? '07:30 PM',
      status: BookingStatus.fromString(map['status']?.toString() ?? 'CONFIRMED'),
      appliedOffer: map['applied_offer']?.toString(),
      paymentId: map['payment_id']?.toString(),
      slotId: map['slot_id']?.toString(),
      createdAt: parsedCreatedAt,
      customerName: resolvedName ?? 'Guest Diner',
      customerPhone: resolvedPhone ?? '+91 98765 43210',
      specialRequests: map['special_requests']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'party_size': partySize,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'booking_date': date,
      'time_slot': timeSlot,
      'status': status.value,
      if (appliedOffer != null) 'applied_offer': appliedOffer,
      if (paymentId != null) 'payment_id': paymentId,
      if (slotId != null) 'slot_id': slotId,
      'created_at': createdAt.toIso8601String(),
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
    String? paymentId,
    String? slotId,
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
      paymentId: paymentId ?? this.paymentId,
      slotId: slotId ?? this.slotId,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      specialRequests: specialRequests ?? this.specialRequests,
    );
  }
}
