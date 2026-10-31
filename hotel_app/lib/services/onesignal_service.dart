import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/onesignal_config.dart';
import '../models/booking_model.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  /// Callback when an incoming booking notification arrives
  Function(BookingModel booking)? onBookingReceived;

  Future<void> initialize() async {
    if (!OneSignalConfig.isConfigured) {
      debugPrint('[OneSignalService] OneSignal App ID not configured; operating in local mode.');
      return;
    }

    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      // 1. Initialize SDK with App ID
      OneSignal.initialize(OneSignalConfig.appId);

      // 2. Request notification permissions from user
      await OneSignal.Notifications.requestPermission(true);

      // 3. Foreground notification display listener
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('[OneSignalService] Foreground push received: ${event.notification.notificationId}');
        final data = event.notification.additionalData;
        if (data != null && (data['type'] == 'NEW_BOOKING' || data.containsKey('booking_id'))) {
          final booking = _parseBookingFromData(data);
          if (booking != null) {
            onBookingReceived?.call(booking);
          }
        }
      });

      // 4. Notification clicked / tapped listener
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('[OneSignalService] Notification tapped: ${event.notification.notificationId}');
        final data = event.notification.additionalData;
        if (data != null && (data['type'] == 'NEW_BOOKING' || data.containsKey('booking_id'))) {
          final booking = _parseBookingFromData(data);
          if (booking != null) {
            onBookingReceived?.call(booking);
          }
        }
      });
    } catch (e) {
      debugPrint('[OneSignalService] Initialization note: $e');
    }
  }

  /// Associate device with restaurant ID as OneSignal external user ID
  Future<void> loginRestaurant(String restaurantId) async {
    if (!OneSignalConfig.isConfigured || restaurantId.isEmpty) return;
    try {
      await OneSignal.login(restaurantId);
      await OneSignal.User.addTagWithKey('restaurant_id', restaurantId);
      debugPrint('[OneSignalService] Logged in device with restaurantId: $restaurantId');
    } catch (e) {
      debugPrint('[OneSignalService] Error logging in: $e');
    }
  }

  /// Unlink user on logout
  Future<void> logout() async {
    if (!OneSignalConfig.isConfigured) return;
    try {
      await OneSignal.logout();
      debugPrint('[OneSignalService] Logged out from OneSignal.');
    } catch (e) {
      debugPrint('[OneSignalService] Error logging out: $e');
    }
  }

  BookingModel? _parseBookingFromData(Map<String, dynamic> data) {
    try {
      return BookingModel(
        bookingId: data['booking_id']?.toString() ?? '',
        userId: data['user_id']?.toString() ?? '',
        restaurantId: data['restaurant_id']?.toString() ?? '',
        restaurantName: data['restaurant_name']?.toString() ?? 'BookNBytes Restaurant',
        partySize: int.tryParse(data['party_size']?.toString() ?? '2') ?? 2,
        date: data['booking_date']?.toString() ?? data['date']?.toString() ?? '',
        timeSlot: data['time_slot']?.toString() ?? '20:00',
        status: BookingStatus.fromString(data['status']?.toString() ?? 'PENDING'),
        appliedOffer: data['applied_offer']?.toString(),
        createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
        customerName: data['customer_name']?.toString() ?? 'Guest Diner',
        customerPhone: data['customer_phone']?.toString(),
      );
    } catch (e) {
      debugPrint('[OneSignalService] Error parsing booking payload: $e');
      return null;
    }
  }
}
