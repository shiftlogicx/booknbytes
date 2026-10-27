import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../config/firebase_config.dart';
import '../models/booking_model.dart';

class BookingService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Get bookings collection reference
  CollectionReference get _bookingsRef => _firestore.collection('bookings');

  /// Stream of today's bookings for a restaurant
  Stream<List<BookingModel>> streamTodayBookings(String restaurantId) {
    if (!FirebaseConfig.isConfigured) {
      return const Stream.empty();
    }
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _bookingsRef
        .where('restaurant_id', isEqualTo: restaurantId)
        .where('date', isEqualTo: today)
        .orderBy('time_slot')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of all bookings for a restaurant
  Stream<List<BookingModel>> streamAllBookings(String restaurantId) {
    if (!FirebaseConfig.isConfigured) {
      return const Stream.empty();
    }
    return _bookingsRef
        .where('restaurant_id', isEqualTo: restaurantId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  /// Get bookings for a specific date
  Future<List<BookingModel>> getBookingsForDate(
    String restaurantId,
    String date,
  ) async {
    final snapshot = await _bookingsRef
        .where('restaurant_id', isEqualTo: restaurantId)
        .where('date', isEqualTo: date)
        .orderBy('time_slot')
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  /// Get bookings filtered by status
  Future<List<BookingModel>> getBookingsByStatus(
    String restaurantId,
    BookingStatus status, {
    String? date,
  }) async {
    Query query = _bookingsRef
        .where('restaurant_id', isEqualTo: restaurantId)
        .where('status', isEqualTo: status.value);

    if (date != null) {
      query = query.where('date', isEqualTo: date);
    }

    final snapshot = await query.orderBy('time_slot').get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  /// Get a single booking by ID
  Future<BookingModel?> getBooking(String bookingId) async {
    final doc = await _bookingsRef.doc(bookingId).get();
    if (doc.exists) {
      return BookingModel.fromFirestore(doc);
    }
    return null;
  }

  /// Update booking status (accept or reject)
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    await _bookingsRef.doc(bookingId).update({
      'status': newStatus.value,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Accept a booking
  Future<void> acceptBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.confirmed);
  }

  /// Reject a booking
  Future<void> rejectBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.rejected);
  }

  /// Get today's booking stats for a restaurant
  Future<Map<String, int>> getTodayStats(String restaurantId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bookings = await getBookingsForDate(restaurantId, today);

    int total = bookings.length;
    int confirmed = 0;
    int pending = 0;

    for (final booking in bookings) {
      if (booking.isConfirmed || booking.isCompleted) confirmed++;
      if (booking.isPending) pending++;
    }

    return {
      'total': total,
      'confirmed': confirmed,
      'pending': pending,
    };
  }

  /// Get booking counts for the last 7 days (for chart)
  Future<Map<String, int>> getWeeklyBookingCounts(String restaurantId) async {
    final counts = <String, int>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final bookings = await getBookingsForDate(restaurantId, dateStr);
      counts[DateFormat('EEE').format(date)] = bookings.length;
    }

    return counts;
  }

  /// Stream pending bookings count
  Stream<int> streamPendingCount(String restaurantId) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _bookingsRef
        .where('restaurant_id', isEqualTo: restaurantId)
        .where('date', isEqualTo: today)
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
