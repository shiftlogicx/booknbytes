import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/booking_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRinging = false;
  Timer? _snoozeTimer;

  /// Callback when a booking alert should be shown
  Function(BookingModel booking)? onIncomingBooking;

  /// Initialize local notifications
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions on Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Show a full-screen notification for incoming booking
  Future<void> showBookingNotification(BookingModel booking) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_alerts',
      'Booking Alerts',
      channelDescription: 'Alerts for new incoming bookings',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 120000, // 2 minutes
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      booking.bookingId.hashCode,
      '🔔 New Booking!',
      '${booking.customerName ?? 'Guest'} · ${booking.partySize} guests · ${booking.timeSlot}',
      details,
      payload: booking.bookingId,
    );
  }

  /// Start playing alert sound in a loop
  Future<void> startRinging() async {
    if (_isRinging) return;
    _isRinging = true;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Use a system-like alert tone. The asset can be replaced with a custom one.
      await _audioPlayer.setSource(AssetSource('sounds/alert_tone.mp3'));
      await _audioPlayer.resume();
    } catch (e) {
      // If custom sound fails, try to play using a URL-based fallback
      print('Audio playback error: $e');
      // The alert overlay visual will still work even without sound
    }
  }

  /// Stop playing alert sound
  Future<void> stopRinging() async {
    _isRinging = false;
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Snooze the alert for a specified duration (default 2 minutes)
  void snooze(BookingModel booking, {Duration duration = const Duration(minutes: 2)}) {
    stopRinging();
    _snoozeTimer?.cancel();
    _snoozeTimer = Timer(duration, () {
      // Re-trigger the alert after snooze
      onIncomingBooking?.call(booking);
    });
  }

  /// Cancel any active snooze timer
  void cancelSnooze() {
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // The app will handle navigation through the FCM service
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Dispose resources
  void dispose() {
    _snoozeTimer?.cancel();
    _audioPlayer.dispose();
  }
}
