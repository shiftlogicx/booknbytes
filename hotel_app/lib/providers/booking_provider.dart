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
        status: BookingStatus.confirmed,
        appliedOffer: 'flat_10',
        createdAt: DateTime.parse('2026-10-25T11:00:00Z'),
      ),
      BookingModel(
        bookingId: 'bk_889901',
        userId: 'usr_33445def',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        partySize: 2,
        date: '2026-10-25',
        timeSlot: '20:30',
        status: BookingStatus.pending,
        appliedOffer: 'taste_20',
        createdAt: DateTime.parse('2026-10-25T16:20:00Z'),
      ),
      BookingModel(
        bookingId: 'bk_889902',
        userId: 'usr_77889ghi',
        restaurantId: 'res_12345xyz',
        restaurantName: 'Mahesh Lunch Home',
        partySize: 6,
        date: '2026-10-26',
        timeSlot: '19:00',
        status: BookingStatus.confirmed,
        createdAt: DateTime.parse('2026-10-25T14:15:00Z'),
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

  void addNewIncomingBooking(BookingModel booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }
}
