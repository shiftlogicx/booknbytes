import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? _vibrateTimer;

  /// Callback when a booking alert should be shown
  Function(BookingModel booking)? onIncomingBooking;

  /// Initialize local notifications & audio session
  Future<void> initialize() async {
    // Configure iOS / Android audio sessions to playback over mute/silent mode
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] AudioContext configuration note: $e');
    }

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

  /// Start playing alert sound in a loop with synchronous haptic ringing
  Future<void> startRinging() async {
    if (_isRinging) return;
    _isRinging = true;

    // Trigger immediate haptics & start continuous vibration pulses
    HapticFeedback.heavyImpact();
    _vibrateTimer?.cancel();
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (_isRinging) {
        HapticFeedback.heavyImpact();
      }
    });

    try {
      SystemSound.play(SystemSoundType.alert);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      
      try {
        await _audioPlayer.play(AssetSource('sounds/alert_tone.wav'));
      } catch (_) {
        try {
          await _audioPlayer.play(AssetSource('sounds/alert_tone.m4a'));
        } catch (_) {
          await _audioPlayer.play(AssetSource('sounds/alert_tone.mp3'));
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Audio playback notice: $e');
    }
  }

  /// Stop playing alert sound
  Future<void> stopRinging() async {
    _isRinging = false;
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('[NotificationService] Error stopping audio: $e');
    }
  }

  /// Play high-definition acceptance confirmation ringtone / chime
  Future<void> playAcceptChime() async {
    try {
      final chimePlayer = AudioPlayer();
      await chimePlayer.setVolume(1.0);
      try {
        await chimePlayer.play(AssetSource('sounds/accept_chime.wav'));
      } catch (_) {
        await chimePlayer.play(AssetSource('sounds/accept_chime.m4a'));
      }
    } catch (e) {
      debugPrint('[NotificationService] Error playing accept chime: $e');
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
