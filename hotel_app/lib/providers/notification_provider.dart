import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/notification_service.dart';
import '../screens/alerts/incoming_booking_alert.dart';
import '../main.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  BookingModel? _activeAlertBooking;
  bool _isAlertVisible = false;

  BookingModel? get activeAlertBooking => _activeAlertBooking;
  bool get isAlertVisible => _isAlertVisible;

  NotificationProvider() {
    _notificationService.onIncomingBooking = (booking) {
      triggerIncomingBookingAlert(booking);
    };
  }

  Future<void> testAlarm() async {
    await _notificationService.startRinging();
    Future.delayed(const Duration(seconds: 4), () {
      _notificationService.stopRinging();
    });
  }

  void triggerIncomingBookingAlert(BookingModel booking) {
    if (_isAlertVisible && _activeAlertBooking?.bookingId == booking.bookingId) {
      return;
    }
    _activeAlertBooking = booking;
    _isAlertVisible = true;
    _notificationService.startRinging();
    notifyListeners();

    // Present the full-screen MyGate-style dialog globally over the active screen
    final nav = appNavigatorKey.currentState;
    if (nav != null) {
      nav.push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, _, __) => IncomingBookingAlertScreen(booking: booking),
        ),
      );
    }
  }

  void acceptBooking() {
    _notificationService.stopRinging();
    _notificationService.playAcceptChime();
    _isAlertVisible = false;
    _activeAlertBooking = null;
    notifyListeners();
  }

  void playAcceptChime() {
    _notificationService.playAcceptChime();
  }

  void snoozeAlert() {
    if (_activeAlertBooking != null) {
      _notificationService.snooze(_activeAlertBooking!);
    } else {
      _notificationService.stopRinging();
    }
    _isAlertVisible = false;
    _activeAlertBooking = null;
    notifyListeners();
  }

  void dismissAlert() {
    _notificationService.stopRinging();
    _isAlertVisible = false;
    _activeAlertBooking = null;
    notifyListeners();
  }
}
