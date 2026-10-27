import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../config/firebase_config.dart';
import 'notification_service.dart';

/// Top-level background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background FCM message received: ${message.messageId}');
  // The notification service will handle showing the full-screen alert
  // when the app opens from the background notification
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  /// Callback to trigger the full-screen booking alert in the app
  Function(BookingModel booking)? onBookingReceived;

  /// Initialize FCM and set up message handlers
  Future<void> initialize() async {
    // Only attempt to initialize FCM if Firebase is actively configured
    if (!FirebaseConfig.isConfigured) {
      debugPrint('[FCMService] Firebase credentials not configured; skipping FCM setup for mock mode.');
      return;
    }

    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      print('FCM Permission status: ${settings.authorizationStatus}');

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when the app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    } catch (e) {
      debugPrint('[FCMService] FCM init bypassed: $e');
    }

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Get the current FCM device token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Listen for token refreshes
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Subscribe to restaurant-specific topic
  Future<void> subscribeToRestaurant(String restaurantId) async {
    await _messaging.subscribeToTopic('restaurant_$restaurantId');
    print('Subscribed to topic: restaurant_$restaurantId');
  }

  /// Unsubscribe from restaurant-specific topic
  Future<void> unsubscribeFromRestaurant(String restaurantId) async {
    await _messaging.unsubscribeFromTopic('restaurant_$restaurantId');
    print('Unsubscribed from topic: restaurant_$restaurantId');
  }

  /// Handle foreground messages — triggers priority ringing alert
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground FCM: ${message.messageId}');
    print('Data: ${message.data}');

    final data = message.data;

    // Check if this is a new booking notification
    if (data['type'] == 'NEW_BOOKING' || data.containsKey('booking_id')) {
      final booking = _parseBookingFromData(data);
      if (booking != null) {
        // Trigger the full-screen alert overlay
        onBookingReceived?.call(booking);

        // Also show a local notification as backup
        _notificationService.showBookingNotification(booking);
      }
    }
  }

  /// Handle when app is opened from a background/terminated notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.messageId}');

    final data = message.data;

    if (data['type'] == 'NEW_BOOKING' || data.containsKey('booking_id')) {
      final booking = _parseBookingFromData(data);
      if (booking != null) {
        // Trigger the full-screen alert
        onBookingReceived?.call(booking);
      }
    }
  }

  /// Parse booking data from FCM payload
  BookingModel? _parseBookingFromData(Map<String, dynamic> data) {
    try {
      // FCM data values are always strings, so we need to handle conversion
      return BookingModel(
        bookingId: data['booking_id'] ?? '',
        userId: data['user_id'] ?? '',
        restaurantId: data['restaurant_id'] ?? '',
        restaurantName: data['restaurant_name'] ?? '',
        partySize: int.tryParse(data['party_size']?.toString() ?? '1') ?? 1,
        date: data['date'] ?? '',
        timeSlot: data['time_slot'] ?? '',
        status: BookingStatus.fromString(data['status'] ?? 'PENDING'),
        appliedOffer: data['applied_offer'],
        createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
        customerName: data['customer_name'] ?? 'Guest',
        customerPhone: data['customer_phone'],
        specialRequests: data['special_requests'],
      );
    } catch (e) {
      print('Error parsing booking from FCM data: $e');
      return null;
    }
  }

  /// Delete token on sign out
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
  }
}
