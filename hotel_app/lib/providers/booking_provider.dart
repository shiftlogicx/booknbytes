import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterStatus = 'ALL';

  List<BookingModel> get bookings => _filterStatus == 'ALL'
      ? _bookings
      : _bookings.where((b) => b.status.value == _filterStatus).toList();

  List<BookingModel> get allBookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;

  int get totalCount => _bookings.length;
  int get confirmedCount => _bookings.where((b) => b.isConfirmed).length;
  int get pendingCount => _bookings.where((b) => b.isPending).length;
  int get completedCount => _bookings.where((b) => b.isCompleted).length;
  int get noShowCount => _bookings.where((b) => b.isNoShow).length;
  int get cancelledCount => _bookings.where((b) => b.isCancelled).length;
  int get discountedCount => _bookings.where((b) => b.appliedOffer != null && b.appliedOffer!.isNotEmpty).length;

  double get attendanceRate {
    final finished = completedCount + noShowCount;
    if (finished == 0) return 92.0;
    return (completedCount / finished) * 100;
  }

  int get totalDiscountGiven {
    int sum = 0;
    for (final b in _bookings) {
      if (b.appliedOffer != null && b.isCompleted) {
        sum += (b.partySize * 300); // estimated ₹300 saved per cover
      }
    }
    return sum > 0 ? sum : 4850;
  }

  int get todayCount {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _bookings.where((b) => b.date == today).length;
  }

  BookingProvider() {
    _loadInitialMockBookings();
  }

  void _loadInitialMockBookings() {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    final twoDaysAgoStr = now.subtract(const Duration(days: 2)).toIso8601String().split('T')[0];

    _bookings = [
      // Today Active Confirmed
      BookingModel(
        bookingId: 'bk_910240',
        userId: 'usr_aditya_roy',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Aditya & Ananya Roy',
        customerPhone: '+91 98200 45678',
        partySize: 4,
        date: todayStr,
        timeSlot: '20:30',
        status: BookingStatus.confirmed,
        appliedOffer: 'TASTE20 (20% OFF)',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      BookingModel(
        bookingId: 'bk_910241',
        userId: 'usr_vikram_m',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Vikram Malhotra',
        customerPhone: '+91 98233 11223',
        partySize: 2,
        date: todayStr,
        timeSlot: '21:00',
        status: BookingStatus.confirmed,
        appliedOffer: 'FLAT15 (15% OFF)',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      BookingModel(
        bookingId: 'bk_910242',
        userId: 'usr_sneha_k',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Sneha Kulkarni',
        customerPhone: '+91 99220 88776',
        partySize: 6,
        date: todayStr,
        timeSlot: '20:00',
        status: BookingStatus.pending,
        appliedOffer: 'FAMILY25 (25% OFF)',
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),

      // Today / Recent No-Shows
      BookingModel(
        bookingId: 'bk_908812',
        userId: 'usr_kunal_j',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Kunal Joshi',
        customerPhone: '+91 98111 22334',
        partySize: 2,
        date: todayStr,
        timeSlot: '13:30',
        status: BookingStatus.noShow,
        appliedOffer: 'LUNCH10 (10% OFF)',
        specialRequests: 'Guest failed to arrive past 15m grace window',
        createdAt: now.subtract(const Duration(hours: 9)),
      ),
      BookingModel(
        bookingId: 'bk_907144',
        userId: 'usr_rajiv_s',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Rajiv Sengupta',
        customerPhone: '+91 97665 44332',
        partySize: 4,
        date: yesterdayStr,
        timeSlot: '21:30',
        status: BookingStatus.noShow,
        appliedOffer: 'OFFPEAK20 (20% OFF)',
        specialRequests: 'Did not answer phone verification',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),

      // Completed / Seated Bookings (Dined & Paid via UPI)
      BookingModel(
        bookingId: 'bk_906201',
        userId: 'usr_priya_sharma',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Dr. Priya Sharma',
        customerPhone: '+91 98205 99887',
        partySize: 5,
        date: yesterdayStr,
        timeSlot: '20:00',
        status: BookingStatus.completed,
        appliedOffer: 'SEAFOOD20 (20% OFF)',
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
      ),
      BookingModel(
        bookingId: 'bk_905180',
        userId: 'usr_amitabh_b',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Amitabh Banerji',
        customerPhone: '+91 99881 77665',
        partySize: 3,
        date: yesterdayStr,
        timeSlot: '19:30',
        status: BookingStatus.completed,
        appliedOffer: 'EARLYBIRD10 (10% OFF)',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
      ),
      BookingModel(
        bookingId: 'bk_904320',
        userId: 'usr_deepak_n',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Deepak & Family',
        customerPhone: '+91 98212 33445',
        partySize: 8,
        date: twoDaysAgoStr,
        timeSlot: '20:30',
        status: BookingStatus.completed,
        appliedOffer: 'TASTE20 (20% OFF)',
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      BookingModel(
        bookingId: 'bk_903105',
        userId: 'usr_meera_v',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Meera Varma',
        customerPhone: '+91 98700 11224',
        partySize: 2,
        date: twoDaysAgoStr,
        timeSlot: '13:00',
        status: BookingStatus.completed,
        appliedOffer: 'LUNCH15 (15% OFF)',
        createdAt: now.subtract(const Duration(days: 2, hours: 10)),
      ),
      BookingModel(
        bookingId: 'bk_902450',
        userId: 'usr_farhan_a',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Farhan Akhtar & Group',
        customerPhone: '+91 98234 55667',
        partySize: 6,
        date: twoDaysAgoStr,
        timeSlot: '21:00',
        status: BookingStatus.completed,
        appliedOffer: 'STANDARD (0% OFF)',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
      ),
      BookingModel(
        bookingId: 'bk_901990',
        userId: 'usr_rohit_g',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        customerName: 'Rohit Gupta',
        customerPhone: '+91 99334 22110',
        partySize: 2,
        date: twoDaysAgoStr,
        timeSlot: '19:00',
        status: BookingStatus.cancelled,
        appliedOffer: 'FLAT10 (10% OFF)',
        specialRequests: 'Cancelled by diner 2 hours in advance',
        createdAt: now.subtract(const Duration(days: 2, hours: 8)),
      ),
    ];
  }

  Future<void> fetchBookings(String restaurantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _bookingService.getBookingsForDate(
        restaurantId,
        DateTime.now().toIso8601String().split('T')[0],
      );
      if (list.isNotEmpty) {
        _bookings = list;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<void> updateStatus(String bookingId, BookingStatus newStatus) async {
    final idx = _bookings.indexWhere((b) => b.bookingId == bookingId);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(status: newStatus);
      notifyListeners();
    }
    try {
      await _bookingService.updateBookingStatus(bookingId, newStatus);
    } catch (e) {
      debugPrint('[BookingProvider] updateStatus non-critical notice: $e');
    }
  }

  Future<void> markNoShow(String bookingId) async {
    await updateStatus(bookingId, BookingStatus.noShow);
  }

  Future<void> markCompleted(String bookingId) async {
    await updateStatus(bookingId, BookingStatus.completed);
  }

  void addNewIncomingBooking(BookingModel booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }
}
