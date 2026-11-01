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
  final AudioPlayer _keepAlivePlayer = AudioPlayer();

  bool _isRinging = false;
  bool _isKeepAliveActive = false;
  Timer? _snoozeTimer;
  Timer? _vibrateTimer;

  /// Callback when a booking alert should be shown
  Function(BookingModel booking)? onIncomingBooking;

  /// Callback when a notification action is tapped
  Function(String bookingId, String actionId)? onNotificationAction;

  /// Start background silent keep-alive audio session (prevents iOS from suspending sockets)
  Future<void> startBackgroundKeepAlive() async {
    if (_isKeepAliveActive || _isRinging) return;
    _isKeepAliveActive = true;
    try {
      await _keepAlivePlayer.setReleaseMode(ReleaseMode.loop);
      await _keepAlivePlayer.setVolume(0.01);
      await _keepAlivePlayer.play(AssetSource('sounds/silence.wav'));
      debugPrint('[NotificationService] Background keep-alive audio session running.');
    } catch (e) {
      debugPrint('[NotificationService] Keep-alive player note: $e');
    }
  }

  Future<void> pauseBackgroundKeepAlive() async {
    try {
      await _keepAlivePlayer.pause();
    } catch (_) {}
  }

  Future<void> resumeBackgroundKeepAlive() async {
    if (_isRinging) return;
    try {
      await _keepAlivePlayer.resume();
    } catch (_) {
      _isKeepAliveActive = false;
      await startBackgroundKeepAlive();
    }
  }

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
              AVAudioSessionOptions.mixWithOthers,
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

    final darwinCategories = <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        'booking_alert_category',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'action_accept',
            'Accept Reservation',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            'action_view',
            'View Booking',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.customDismissAction,
        },
      ),
    ];

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
      notificationCategories: darwinCategories,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create high-importance Android channel with alert sound
    const androidChannel = AndroidNotificationChannel(
      'booking_alerts',
      'Booking Alerts',
      description: 'Priority alarm channel for incoming reservations',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alert_tone'),
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Request permissions on Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Start background keep-alive to preserve active WebSocket connection
    await startBackgroundKeepAlive();
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
      sound: RawResourceAndroidNotificationSound('alert_tone'),
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 120000, // 2 minutes
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_accept',
          'ACCEPT',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'action_view',
          'VIEW',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alert_tone.wav',
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'booking_alert_category',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      booking.bookingId.hashCode,
      '🔔 New Reservation Request!',
      '${booking.customerName ?? 'Guest'} · ${booking.partySize} guests at ${booking.timeSlot}',
      details,
      payload: booking.bookingId,
    );
  }

  /// Start playing alert sound in a loop with synchronous haptic ringing
  Future<void> startRinging() async {
    if (_isRinging) return;
    _isRinging = true;

    // Pause silent keep-alive while ringing loudly
    await pauseBackgroundKeepAlive();

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
    // Resume silent keep-alive session to maintain active background sockets
    await resumeBackgroundKeepAlive();
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

  /// Handle notification tap & quick action buttons
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: action=${response.actionId}, payload=${response.payload}');
    final bookingId = response.payload;
    if (bookingId != null && bookingId.isNotEmpty) {
      onNotificationAction?.call(bookingId, response.actionId ?? '');
    }
  }

  /// Dispose resources
  void dispose() {
    _snoozeTimer?.cancel();
    _audioPlayer.dispose();
    _keepAlivePlayer.dispose();
  }
}
