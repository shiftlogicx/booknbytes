import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/restaurant_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _allBookings = [];
  List<BookingModel> _upcomingBookings = [];
  List<BookingModel> _pastBookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  BookingModel? _lastCreatedBooking;

  // Booking form state
  int _partySize = 2;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  RestaurantOffer? _selectedOffer;

  // Getters
  List<BookingModel> get allBookings => _allBookings;
  List<BookingModel> get upcomingBookings => _upcomingBookings;
  List<BookingModel> get pastBookings => _pastBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BookingModel? get lastCreatedBooking => _lastCreatedBooking;

  int get partySize => _partySize;
  DateTime get selectedDate => _selectedDate;
  String? get selectedTimeSlot => _selectedTimeSlot;
  RestaurantOffer? get selectedOffer => _selectedOffer;

  /// Set party size
  void setPartySize(int size) {
    _partySize = size.clamp(1, 10);
    notifyListeners();
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _selectedTimeSlot = null; // Reset time slot when date changes
    notifyListeners();
  }

  /// Set selected time slot
  void setSelectedTimeSlot(String? slot) {
    _selectedTimeSlot = slot;
    notifyListeners();
  }

  /// Set selected offer
  void setSelectedOffer(RestaurantOffer? offer) {
    if (_selectedOffer?.offerId == offer?.offerId) {
      _selectedOffer = null;
    } else {
      _selectedOffer = offer;
    }
    notifyListeners();
  }

  /// Reset booking form
  void resetBookingForm() {
    _partySize = 2;
    _selectedDate = DateTime.now();
    _selectedTimeSlot = null;
    _selectedOffer = null;
    _errorMessage = null;
    _lastCreatedBooking = null;
    notifyListeners();
  }

  /// Create a new booking
  Future<bool> createBooking({
    required String userId,
    required String restaurantId,
    required String restaurantName,
  }) async {
    if (_selectedTimeSlot == null) {
      _errorMessage = 'Please select a time slot';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final booking = await _bookingService.createBooking(
        userId: userId,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        partySize: _partySize,
        date: dateStr,
        timeSlot: _selectedTimeSlot!,
        appliedOffer: _selectedOffer?.offerId,
      );

      _lastCreatedBooking = booking;
      await fetchUserBookings(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all bookings for current user
  Future<void> fetchUserBookings(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _allBookings = await _bookingService.getUserBookings(userId);
      _upcomingBookings = _allBookings.where((b) => b.isUpcoming).toList();
      _pastBookings = _allBookings.where((b) => b.isPast).toList();
    } catch (e) {
      _errorMessage = 'Failed to load bookings: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(BookingModel booking) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _bookingService.cancelBooking(booking);
      await fetchUserBookings(booking.userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel booking: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
