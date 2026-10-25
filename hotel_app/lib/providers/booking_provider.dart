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
      : _bookings.where((b) => b.status == _filterStatus).toList();

  List<BookingModel> get allBookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;

  int get totalCount => _bookings.length;
  int get confirmedCount => _bookings.where((b) => b.status == 'CONFIRMED').length;
  int get pendingCount => _bookings.where((b) => b.status == 'PENDING').length;
  int get todayCount {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _bookings.where((b) => b.date == today).length;
  }

  BookingProvider() {
    _loadInitialMockBookings();
  }

  void _loadInitialMockBookings() {
    _bookings = [
      BookingModel(
        bookingId: 'bk_889900',
        userId: 'usr_98765abc',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        partySize: 4,
        date: '2026-10-25',
        timeSlot: '19:30',
        status: 'CONFIRMED',
        appliedOffer: 'flat_10',
        createdAt: '2026-10-25T11:00:00Z',
      ),
      BookingModel(
        bookingId: 'bk_889901',
        userId: 'usr_33445def',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        partySize: 2,
        date: '2026-10-25',
        timeSlot: '20:30',
        status: 'PENDING',
        appliedOffer: 'dineout_20',
        createdAt: '2026-10-25T16:20:00Z',
      ),
      BookingModel(
        bookingId: 'bk_889902',
        userId: 'usr_77889ghi',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        partySize: 6,
        date: '2026-10-26',
        timeSlot: '19:00',
        status: 'CONFIRMED',
        createdAt: '2026-10-25T14:15:00Z',
      ),
    ];
  }

  Future<void> fetchBookings(String restaurantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _bookingService.getBookingsForRestaurant(restaurantId);
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

  Future<void> updateStatus(String bookingId, String newStatus) async {
    final idx = _bookings.indexWhere((b) => b.bookingId === bookingId);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(status: newStatus);
      notifyListeners();
    }
    await _bookingService.updateBookingStatus(bookingId, newStatus);
  }

  void addNewIncomingBooking(BookingModel booking) {
    // Insert at front
    _bookings.insert(0, booking);
    notifyListeners();
  }
}

extension on BookingModel {
  BookingModel copyWith({
    String? status,
  }) {
    return BookingModel(
      bookingId: bookingId,
      userId: userId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      partySize: partySize,
      date: date,
      timeSlot: timeSlot,
      status: status ?? this.status,
      appliedOffer: appliedOffer,
      createdAt: createdAt,
    );
  }
}
