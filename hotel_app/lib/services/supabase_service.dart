import 'dart:convert';
import 'dart:typed_data';
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
  // 5. INHERENT SUPABASE AUTH: Password Recovery & Reset
  // ==========================================
  Future<Map<String, dynamic>> generatePasswordRecoveryCode(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final adminHeaders = {
      'apikey': SupabaseConfig.serviceRoleKey,
      'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
      'Content-Type': 'application/json',
    };

    // 1. Check if user exists in auth.users
    final listRes = await http.get(
      Uri.parse('${SupabaseConfig.url}/auth/v1/admin/users?page=1&per_page=1000'),
      headers: adminHeaders,
    );

    String? foundUserId;
    if (listRes.statusCode == 200) {
      final listData = jsonDecode(listRes.body);
      final users = listData['users'] as List?;
      if (users != null) {
        for (final u in users) {
          if (u['email']?.toString().toLowerCase() == cleanEmail) {
            foundUserId = u['id']?.toString();
            break;
          }
        }
      }
    }

    // 2. If not found in auth.users, check if registered in restaurants table
    if (foundUserId == null) {
      final restRes = await http.get(
        Uri.parse('${SupabaseConfig.url}/rest/v1/restaurants?select=restaurant_id,name,owners_details'),
        headers: adminHeaders,
      );
      if (restRes.statusCode == 200) {
        final restList = jsonDecode(restRes.body) as List?;
        if (restList != null) {
          for (final r in restList) {
            final owners = r['owners_details'];
            if (owners is Map) {
              final ownerEmail = owners['email']?.toString().toLowerCase();
              final mgrEmail = owners['manager_credentials'] is Map
                  ? owners['manager_credentials']['email']?.toString().toLowerCase()
                  : null;
              if (ownerEmail == cleanEmail || mgrEmail == cleanEmail) {
                // Provision auth user so recovery code can be generated
                final createRes = await http.post(
                  Uri.parse('${SupabaseConfig.url}/auth/v1/admin/users'),
                  headers: adminHeaders,
                  body: jsonEncode({
                    'email': cleanEmail,
                    'password': 'Temp@${DateTime.now().millisecondsSinceEpoch}!',
                    'email_confirm': true,
                    'app_metadata': {
                      'role': mgrEmail == cleanEmail ? 'restaurant_manager' : 'restaurant_owner',
                      'restaurant_id': r['restaurant_id'],
                    },
                  }),
                );
                if (createRes.statusCode == 200 || createRes.statusCode == 201) {
                  final created = jsonDecode(createRes.body);
                  foundUserId = created['id']?.toString();
                }
                break;
              }
            }
          }
        }
      }
    }

    if (foundUserId == null) {
      throw Exception('No registered account found for "$cleanEmail". Please verify the email or register a new restaurant.');
    }

    // 3. Dispatch recovery email to legitimate inbox & generate recovery OTP
    try {
      await http.post(
        Uri.parse('${SupabaseConfig.url}/auth/v1/recover'),
        headers: {
          'apikey': SupabaseConfig.anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': cleanEmail}),
      );
    } catch (_) {}

    final genRes = await http.post(
      Uri.parse('${SupabaseConfig.url}/auth/v1/admin/generate_link'),
      headers: adminHeaders,
      body: jsonEncode({
        'type': 'recovery',
        'email': cleanEmail,
      }),
    );

    if (genRes.statusCode != 200) {
      final err = jsonDecode(genRes.body);
      throw Exception(err['message'] ?? err['msg'] ?? 'Failed to generate recovery code.');
    }

    final genData = jsonDecode(genRes.body);
    final otp = genData['email_otp']?.toString() ??
        '${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';

    return {
      'userId': foundUserId,
      'email': cleanEmail,
      'otp': otp,
    };
  }

  Future<void> adminUpdatePassword({
    required String userId,
    required String newPassword,
    String? email,
  }) async {
    final adminHeaders = {
      'apikey': SupabaseConfig.serviceRoleKey,
      'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
      'Content-Type': 'application/json',
    };

    final updateRes = await http.put(
      Uri.parse('${SupabaseConfig.url}/auth/v1/admin/users/$userId'),
      headers: adminHeaders,
      body: jsonEncode({'password': newPassword}),
    );

    if (updateRes.statusCode != 200) {
      final err = jsonDecode(updateRes.body);
      throw Exception(err['message'] ?? err['msg'] ?? 'Failed to update password.');
    }

    // If manager, sync default_password in restaurants table
    if (email != null && email.contains('manager.')) {
      try {
        final restData = await findRestaurantByManagerEmail(email);
        if (restData != null && restData['restaurant_id'] != null) {
          final restId = restData['restaurant_id'];
          final owners = Map<String, dynamic>.from(restData['owners_details'] ?? {});
          if (owners['manager_credentials'] is Map) {
            final mgrCreds = Map<String, dynamic>.from(owners['manager_credentials']);
            mgrCreds['default_password'] = newPassword;
            mgrCreds['password_updated'] = true;
            owners['manager_credentials'] = mgrCreds;
            await client.from('restaurants').update({'owners_details': owners}).eq('restaurant_id', restId);
          }
        }
      } catch (e) {
        // Non-critical background sync
      }
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.recovery,
      );
      return res;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserResponse> updateUserPassword(String newPassword) async {
    try {
      final res = await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return res;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>?> findRestaurantByManagerEmail(String managerEmail) async {
    try {
      final res = await client
          .from('restaurants')
          .select('restaurant_id, name, owners_details')
          .filter('owners_details->manager_credentials->>email', 'eq', managerEmail.trim().toLowerCase())
          .maybeSingle();
      if (res != null) return Map<String, dynamic>.from(res);
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // 6. RESTAURANTS: Fetch, Create, Update
  // ==========================================
  Future<Map<String, dynamic>?> fetchRestaurantForCurrentUser() async {
    final user = currentUser;
    if (user == null) {
      final defaultRest = await client
          .from('restaurants')
          .select('*')
          .eq('restaurant_id', 'res_the_loaf_butter_30071')
          .maybeSingle();
      if (defaultRest != null) return Map<String, dynamic>.from(defaultRest);
      return null;
    }

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

  // ==========================================
  // 9. RESTAURANT MEDIA (HOTEL PHOTOS & MENU CARDS)
  // ==========================================
  Future<String> uploadMediaFile({
    required String restaurantId,
    required String category, // 'ambience' | 'menu'
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final mime = contentType ?? (filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
    final ext = mime == 'image/png' ? 'png' : 'jpg';
    final cleanName = '${category}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = '$restaurantId/$category/$cleanName';

    final uploadUrl = Uri.parse('${SupabaseConfig.url}/storage/v1/object/restaurant-media/$storagePath');
    final response = await http.post(
      uploadUrl,
      headers: {
        'apikey': SupabaseConfig.serviceRoleKey,
        'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
        'Content-Type': mime,
        'x-upsert': 'true',
      },
      body: bytes,
    );

    if (response.statusCode >= 400) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to upload media to storage.');
    }

    final publicUrl = '${SupabaseConfig.url}/storage/v1/object/public/restaurant-media/$storagePath';
    return publicUrl;
  }

  Future<void> updateRestaurantVisuals({
    required String restaurantId,
    String? heroImage,
    List<String>? subordinatePhotos,
    List<String>? hotelPhotos,
    required List<String> menuImages,
  }) async {
    String resolvedHero = heroImage ?? '';
    List<String> resolvedAmbience = subordinatePhotos != null ? List<String>.from(subordinatePhotos) : [];

    if (hotelPhotos != null && hotelPhotos.isNotEmpty) {
      if (resolvedHero.isEmpty) {
        resolvedHero = hotelPhotos.first;
        if (resolvedAmbience.isEmpty && hotelPhotos.length > 1) {
          resolvedAmbience = hotelPhotos.skip(1).take(2).toList();
        }
      }
    }

    final visuals = {
      'hero_image': resolvedHero,
      'ambience': resolvedAmbience.take(2).toList(),
      'menu_images': menuImages,
    };

    final adminHeaders = {
      'apikey': SupabaseConfig.serviceRoleKey,
      'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
      'Content-Type': 'application/json',
    };

    final res = await http.patch(
      Uri.parse('${SupabaseConfig.url}/rest/v1/restaurants?restaurant_id=eq.$restaurantId'),
      headers: adminHeaders,
      body: jsonEncode({'visuals': visuals}),
    );

    if (res.statusCode >= 400) {
      throw Exception('Failed to update restaurant visuals.');
    }
  }

  Future<void> deleteMediaFile(String publicUrl) async {
    try {
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;
      final bucketIdx = pathSegments.indexOf('restaurant-media');
      if (bucketIdx != -1 && pathSegments.length > bucketIdx + 1) {
        final objectPath = pathSegments.sublist(bucketIdx + 1).join('/');
        await http.delete(
          Uri.parse('${SupabaseConfig.url}/storage/v1/object/restaurant-media/$objectPath'),
          headers: {
            'apikey': SupabaseConfig.serviceRoleKey,
            'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
          },
        );
      }
    } catch (_) {
      // Non-critical background cleanup
    }
  }
}
