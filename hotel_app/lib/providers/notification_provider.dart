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

  void triggerIncomingBookingAlert(BookingModel booking) {
    _activeAlertBooking = booking;
    _isAlertVisible = true;
    _notificationService.playRingtone();
    notifyListeners();
  }

  void acceptBooking() {
    _notificationService.stopRingtone();
    _isAlertVisible = false;
    _activeAlertBooking = null;
    notifyListeners();
  }

  void snoozeAlert() {
    _notificationService.stopRingtone();
    _isAlertVisible = false;
    if (_activeAlertBooking != null) {
      _notificationService.snoozeBooking(_activeAlertBooking!);
    }
    _activeAlertBooking = null;
    notifyListeners();
  }

  void dismissAlert() {
    _notificationService.stopRingtone();
    _isAlertVisible = false;
    _activeAlertBooking = null;
    notifyListeners();
  }
}
