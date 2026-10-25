import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newBooking('NEW_BOOKING'),
  bookingUpdate('BOOKING_UPDATE'),
  reminder('REMINDER'),
  system('SYSTEM');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.value == type.toUpperCase(),
      orElse: () => NotificationType.system,
    );
  }
}

class NotificationModel {
  final String notificationId;
  final String restaurantId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.restaurantId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(map);
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['created_at'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return NotificationModel(
      notificationId: map['notification_id'] ?? '',
      restaurantId: map['restaurant_id'] ?? '',
      type: NotificationType.fromString(map['type'] ?? 'SYSTEM'),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['is_read'] ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notification_id': notificationId,
      'restaurant_id': restaurantId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      restaurantId: restaurantId,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
