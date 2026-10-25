import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String phoneNumber;
  final String email;
  final String authProvider;
  final List<String> preferences;
  final int totalBookings;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.authProvider,
    required this.preferences,
    required this.totalBookings,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: data['user_id'] ?? doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      email: data['email'] ?? '',
      authProvider: data['auth_provider'] ?? 'google',
      preferences: List<String>.from(data['preferences'] ?? []),
      totalBookings: data['total_bookings'] ?? 0,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'auth_provider': authProvider,
      'preferences': preferences,
      'total_bookings': totalBookings,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? phoneNumber,
    String? email,
    String? authProvider,
    List<String>? preferences,
    int? totalBookings,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      authProvider: authProvider ?? this.authProvider,
      preferences: preferences ?? this.preferences,
      totalBookings: totalBookings ?? this.totalBookings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
