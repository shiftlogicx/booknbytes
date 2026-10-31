import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/booking_model.dart';
import '../models/slot_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ==========================================
  // 1. EDGE FUNCTION: Signup Restaurant Owner
  // ==========================================
  Future<Map<String, dynamic>> signupOwner({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final url = Uri.parse(SupabaseConfig.fnSignupOwner);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.anonKey,
      },
      body: jsonEncode({
        'name': name.trim(),
        'owner_name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': phone.trim(),
      }),
    );

    final resBody = jsonDecode(response.body);
    if (response.statusCode >= 400 || resBody['error'] != null) {
      throw Exception(resBody['error'] ?? 'Failed to sign up restaurant owner.');
    }

    return Map<String, dynamic>.from(resBody);
  }

  // ==========================================
  // 2. EDGE FUNCTION: Activate Restaurant
  // ==========================================
  Future<Map<String, dynamic>> activateRestaurant({
    required String restaurantId,
    String? authToken,
  }) async {
    final url = Uri.parse(SupabaseConfig.fnActivateRestaurant);
    final token = authToken ?? currentSession?.accessToken ?? SupabaseConfig.serviceRoleKey;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'restaurant_id': restaurantId,
      }),
    );

    final resBody = jsonDecode(response.body);
    if (response.statusCode >= 400 || resBody['error'] != null) {
      throw Exception(resBody['error'] ?? 'Failed to activate restaurant.');
    }

    return Map<String, dynamic>.from(resBody);
  }

  // ==========================================
  // 3. EDGE FUNCTION: Update Manager Password
  // ==========================================
  Future<Map<String, dynamic>> updateManagerPassword({
    required String newPassword,
    String? targetManagerId,
  }) async {
    final url = Uri.parse(SupabaseConfig.fnUpdateManagerPassword);
    final token = currentSession?.accessToken;
    if (token == null) {
      throw Exception('User is not authenticated.');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'new_password': newPassword,
        if (targetManagerId != null) 'target_manager_id': targetManagerId,
      }),
    );

    final resBody = jsonDecode(response.body);
    if (response.statusCode >= 400 || resBody['error'] != null) {
      throw Exception(resBody['error'] ?? 'Failed to update manager password.');
    }

    return Map<String, dynamic>.from(resBody);
  }

  // ==========================================
  // 4. SUPABASE AUTH: Sign In & Out
  // ==========================================
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return res;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ==========================================
  // 5. RESTAURANTS: Fetch, Create, Update
  // ==========================================
  Future<Map<String, dynamic>?> fetchRestaurantForCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;

    final appMeta = user.appMetadata;
    final jwtRestId = appMeta['restaurant_id']?.toString();

    // 1. Try by restaurant_id in app_metadata
    if (jwtRestId != null && jwtRestId.isNotEmpty) {
      final res = await client
          .from('restaurants')
          .select('*')
          .eq('restaurant_id', jwtRestId)
          .maybeSingle();
      if (res != null) return Map<String, dynamic>.from(res);
    }

    // 2. Try by owner_id in owners_details
    final byOwner = await client
        .from('restaurants')
        .select('*')
        .filter('owners_details->>owner_id', 'eq', user.id)
        .order('created_at', ascending: false)
        .limit(1);

    if (byOwner.isNotEmpty) {
      return Map<String, dynamic>.from(byOwner.first);
    }

    // 3. Try by manager_id in manager_credentials
    final byManager = await client
        .from('restaurants')
        .select('*')
        .filter('owners_details->manager_credentials->>manager_id', 'eq', user.id)
        .order('created_at', ascending: false)
        .limit(1);

    if (byManager.isNotEmpty) {
      return Map<String, dynamic>.from(byManager.first);
    }

    // 4. Fallback: try by email match in owners_details
    if (user.email != null) {
      final byEmail = await client
          .from('restaurants')
          .select('*')
          .filter('owners_details->>email', 'eq', user.email!)
          .limit(1);
      if (byEmail.isNotEmpty) {
        return Map<String, dynamic>.from(byEmail.first);
      }
    }

    // 5. Fallback: return first active restaurant so manager can immediately test live data
    final anyActive = await client
        .from('restaurants')
        .select('*')
        .eq('status', 'ACTIVE')
        .order('created_at', ascending: false)
        .limit(1);

    if (anyActive.isNotEmpty) {
      return Map<String, dynamic>.from(anyActive.first);
    }

    return null;
  }

  Future<Map<String, dynamic>> createRestaurant(Map<String, dynamic> data) async {
    final res = await client.from('restaurants').insert(data).select().single();
    return Map<String, dynamic>.from(res);
  }

  Future<void> updateRestaurant(String restaurantId, Map<String, dynamic> data) async {
    await client.from('restaurants').update(data).eq('restaurant_id', restaurantId);
  }

  // ==========================================
  // 6. DAILY SLOTS: Fetch, Insert, Update, Delete
  // ==========================================
  Future<List<DailySlotModel>> fetchDailySlots(String restaurantId) async {
    final data = await client
        .from('daily_slots')
        .select('*')
        .eq('restaurant_id', restaurantId)
        .order('start_datetime', ascending: true);

    return (data as List)
        .map((row) => DailySlotModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<DailySlotModel> insertDailySlot(DailySlotModel slot) async {
    final map = slot.toMap();
    if (slot.slotId.isEmpty) {
      map.remove('slot_id');
    }
    final res = await client.from('daily_slots').insert(map).select().single();
    return DailySlotModel.fromMap(Map<String, dynamic>.from(res));
  }

  Future<void> updateDailySlot(String slotId, Map<String, dynamic> data) async {
    await client.from('daily_slots').update(data).eq('slot_id', slotId);
  }

  Future<void> deleteDailySlot(String slotId) async {
    await client.from('daily_slots').delete().eq('slot_id', slotId);
  }

  // ==========================================
  // 7. BOOKINGS: Fetch, Insert, Update Status, Realtime Stream
  // ==========================================
  Future<BookingModel> insertBooking(BookingModel booking) async {
    final payload = booking.toMap();
    try {
      final res = await client
          .from('bookings')
          .insert(payload)
          .select('*, users(name, phone_number)')
          .single();
      return BookingModel.fromMap(Map<String, dynamic>.from(res));
    } catch (e) {
      if (e.toString().contains('bookings_user_id_fkey')) {
        payload['user_id'] = '6d03741d-db04-4370-bc49-bbb1149a5c33';
        final res = await client
            .from('bookings')
            .insert(payload)
            .select('*, users(name, phone_number)')
            .single();
        return BookingModel.fromMap(Map<String, dynamic>.from(res));
      }
      rethrow;
    }
  }

  Future<List<BookingModel>> fetchBookings(String restaurantId) async {
    final data = await client
        .from('bookings')
        .select('*, users(name, phone_number)')
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => BookingModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await client
        .from('bookings')
        .update({'status': newStatus})
        .eq('booking_id', bookingId);
  }

  Stream<List<BookingModel>> streamBookings(String restaurantId) {
    return client
        .from('bookings')
        .stream(primaryKey: ['booking_id'])
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false)
        .map((list) => list
            .map((row) => BookingModel.fromMap(Map<String, dynamic>.from(row)))
            .toList());
  }

  // ==========================================
  // 8. DISCOUNTS & OFFERS: Update active_offers
  // ==========================================
  Future<void> updateActiveOffers(String restaurantId, List<Map<String, dynamic>> offers) async {
    await client.from('restaurants').update({
      'active_offers': offers,
    }).eq('restaurant_id', restaurantId);
  }
}
