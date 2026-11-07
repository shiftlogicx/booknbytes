import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';
import '../screens/alerts/incoming_booking_alert.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../main.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  BookingModel? _activeAlertBooking;
  bool _isAlertVisible = false;

  // Settings: optional full-screen pulse alert & hardware triggers
  bool _isFullScreenAlertEnabled = true;
  bool _isLoudChimeEnabled = true;
  bool _isHapticVibrationEnabled = true;

  BookingModel? get activeAlertBooking => _activeAlertBooking;
  bool get isAlertVisible => _isAlertVisible;
  bool get isFullScreenAlertEnabled => _isFullScreenAlertEnabled;
  bool get isLoudChimeEnabled => _isLoudChimeEnabled;
  bool get isHapticVibrationEnabled => _isHapticVibrationEnabled;

  static const String _prefFullScreenKey = 'pref_full_screen_alerts';
  static const String _prefLoudChimeKey = 'pref_loud_chime';
  static const String _prefHapticVibrationKey = 'pref_haptic_vibration';

  NotificationProvider() {
    _loadPreferences();
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

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFullScreenAlertEnabled = prefs.getBool(_prefFullScreenKey) ?? true;
      _isLoudChimeEnabled = prefs.getBool(_prefLoudChimeKey) ?? true;
      _isHapticVibrationEnabled = prefs.getBool(_prefHapticVibrationKey) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationProvider] Error loading alert preferences: $e');
    }
  }

  Future<void> setFullScreenAlertEnabled(bool enabled) async {
    if (_isFullScreenAlertEnabled == enabled) return;
    _isFullScreenAlertEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefFullScreenKey, enabled);
    } catch (e) {
      debugPrint('[NotificationProvider] Error saving full-screen alert pref: $e');
    }
  }

  Future<void> setLoudChimeEnabled(bool enabled) async {
    if (_isLoudChimeEnabled == enabled) return;
    _isLoudChimeEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoudChimeKey, enabled);
    } catch (e) {
      debugPrint('[NotificationProvider] Error saving loud chime pref: $e');
    }
  }

  Future<void> setHapticVibrationEnabled(bool enabled) async {
    if (_isHapticVibrationEnabled == enabled) return;
    _isHapticVibrationEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefHapticVibrationKey, enabled);
    } catch (e) {
      debugPrint('[NotificationProvider] Error saving haptic pref: $e');
    }
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

    // 1. Always dispatch system notification to background tray
    _notificationService.showBookingNotification(booking);

    // 2. Full-Screen Alert Toggle Evaluation
    if (_isFullScreenAlertEnabled) {
      // Toggle is ON: pop up full-screen pulse alert over mobile UI & start acoustic ringer
      _activeAlertBooking = booking;
      _isAlertVisible = true;
      notifyListeners();

      if (_isLoudChimeEnabled) {
        _notificationService.startRinging();
      }

      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        nav.push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, _, __) => IncomingBookingAlertScreen(booking: booking),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: child,
              );
            },
          ),
        );
      }
    } else {
      // Toggle is OFF: ONLY background alert is sent! Screen is not hijacked.
      _isAlertVisible = false;
      _activeAlertBooking = null;
      notifyListeners();

      if (_isLoudChimeEnabled) {
        _notificationService.playAcceptChime();
      }

      // Show non-blocking in-app floating banner for active user
      final ctx = appNavigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.maybeOf(ctx)?.clearSnackBars();
        ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.table_restaurant_rounded, color: Color(0xFF00E599), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'New booking: ${booking.customerName ?? "Guest"} (${booking.partySize} Guests · ${booking.timeSlot})',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void acceptBooking() {
    _notificationService.stopRinging();
    _notificationService.playAcceptChime();
    _isAlertVisible = false;
    _activeAlertBooking = null;
    notifyListeners();
  }

  void stopRinging() {
    _notificationService.stopRinging();
    _isAlertVisible = false;
    _activeAlertBooking = null;
    notifyListeners();
  }

  void rejectBooking() {
    _notificationService.stopRinging();
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
