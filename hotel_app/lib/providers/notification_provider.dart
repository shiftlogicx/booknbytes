import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/notification_service.dart';

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
    _activeAlertBooking = booking;
    _isAlertVisible = true;
    _notificationService.startRinging();
    notifyListeners();
  }

  void acceptBooking() {
    _notificationService.stopRinging();
    _isAlertVisible = false;
    _activeAlertBooking = null;
    notifyListeners();
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
