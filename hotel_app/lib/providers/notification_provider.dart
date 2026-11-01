import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
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
    _notificationService.onNotificationAction = (bookingId, actionId) {
      if (actionId == 'action_accept') {
        acceptBooking();
        SupabaseService().updateBookingStatus(bookingId, 'CONFIRMED');
      }
    };
  }

  Future<void> testAlarm() async {
    await _notificationService.startRinging();
    Future.delayed(const Duration(seconds: 4), () {
      _notificationService.stopRinging();
    });
  }

  final Map<String, DateTime> _recentlyAlertedBookings = {};

  void triggerIncomingBookingAlert(BookingModel booking) {
    final bookingKey = booking.bookingId.trim().toLowerCase();
    final now = DateTime.now();

    // Clean up stale entries older than 2 minutes
    _recentlyAlertedBookings.removeWhere(
      (_, time) => now.difference(time).inSeconds > 120,
    );

    // Deduplicate if alert is already on screen or was displayed in the last 45 seconds
    if (_isAlertVisible && _activeAlertBooking?.bookingId.trim().toLowerCase() == bookingKey) {
      debugPrint('[NotificationProvider] Deduplicating alert for $bookingKey (alert currently active on screen)');
      return;
    }

    final lastAlert = _recentlyAlertedBookings[bookingKey];
    if (lastAlert != null && now.difference(lastAlert).inSeconds < 45) {
      debugPrint('[NotificationProvider] Deduplicating alert for $bookingKey (already triggered ${now.difference(lastAlert).inSeconds}s ago)');
      return;
    }
    _recentlyAlertedBookings[bookingKey] = now;

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
