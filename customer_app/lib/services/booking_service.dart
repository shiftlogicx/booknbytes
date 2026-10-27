import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Create a new booking atomically (write booking + decrement slot count)
  Future<BookingModel> createBooking({
    required String userId,
    required String restaurantId,
    required String restaurantName,
    required int partySize,
    required String date,
    required String timeSlot,
    String? appliedOffer,
  }) async {
    final bookingId =
        'bk_${DateTime.now().millisecondsSinceEpoch}';

    final booking = BookingModel(
      bookingId: bookingId,
      userId: userId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      partySize: partySize,
      date: date,
      timeSlot: timeSlot,
      status: 'CONFIRMED',
      appliedOffer: appliedOffer,
      createdAt: DateTime.now(),
    );

    // Use a Firestore transaction for atomicity
    await _firestore.runTransaction((transaction) async {
      // Get restaurant document reference
      final restaurantRef =
          _firestore.collection('restaurants').doc(restaurantId);
      final restaurantDoc = await transaction.get(restaurantRef);

      if (!restaurantDoc.exists) {
        throw Exception('Restaurant not found');
      }

      final data = restaurantDoc.data()!;
      final dailySlots =
          data['daily_slots'] as Map<String, dynamic>? ?? {};
      final daySlots =
          dailySlots[date] as Map<String, dynamic>? ?? {};
      final currentCount = (daySlots[timeSlot] as num?)?.toInt() ?? 0;

      if (currentCount <= 0) {
        throw Exception('This time slot is no longer available');
      }

      // Decrement slot count
      transaction.update(restaurantRef, {
        'daily_slots.$date.$timeSlot': currentCount - 1,
      });

      // Create booking document
      final bookingRef =
          _firestore.collection('bookings').doc(bookingId);
      transaction.set(bookingRef, booking.toFirestore());

      // Increment user's total bookings
      final userRef = _firestore.collection('users').doc(userId);
      transaction.update(userRef, {
        'total_bookings': FieldValue.increment(1),
      });
    });

    return booking;
  }

  /// Get all bookings for a user
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  /// Get upcoming bookings for a user
  Future<List<BookingModel>> getUpcomingBookings(String userId) async {
    final allBookings = await getUserBookings(userId);
    return allBookings.where((b) => b.isUpcoming).toList();
  }

  /// Get past bookings for a user
  Future<List<BookingModel>> getPastBookings(String userId) async {
    final allBookings = await getUserBookings(userId);
    return allBookings.where((b) => b.isPast).toList();
  }

  /// Cancel a booking
  Future<void> cancelBooking(BookingModel booking) async {
    await _firestore.runTransaction((transaction) async {
      // Update booking status
      final bookingRef =
          _firestore.collection('bookings').doc(booking.bookingId);
      transaction.update(bookingRef, {'status': 'CANCELLED'});

      // Restore slot count
      final restaurantRef =
          _firestore.collection('restaurants').doc(booking.restaurantId);
      transaction.update(restaurantRef, {
        'daily_slots.${booking.date}.${booking.timeSlot}':
            FieldValue.increment(1),
      });

      // Decrement user's total bookings
      final userRef =
          _firestore.collection('users').doc(booking.userId);
      transaction.update(userRef, {
        'total_bookings': FieldValue.increment(-1),
      });
    });
  }

  /// Mark booking as completed
  Future<void> completeBooking(String bookingId) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'COMPLETED'});
  }

  /// Get a single booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc =
        await _firestore.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// Listen to user's bookings in real-time
  Stream<List<BookingModel>> userBookingsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }
}
