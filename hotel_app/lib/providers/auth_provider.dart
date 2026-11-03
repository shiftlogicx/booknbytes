import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/onesignal_service.dart';

enum UserRole { owner, manager }

class RestaurantProfileData {
  String restaurantId;
  String name;
  String ownerName;
  String phone;
  String email;
  String upiId;
  String fssaiNumber;
  String address;
  int costForTwo;
  List<String> cuisines;
  String lunchOpen;
  String lunchClose;
  String dinnerOpen;
  String dinnerClose;
  bool isVegOnly;
  bool hasBar;
  bool isAc;
  bool parkingAvailable;
  bool dynamicDiscountEnabled;
  int minDiscount;
  int maxDiscount;
  List<Map<String, dynamic>> activeOffers;
  Map<String, dynamic>? managerCredentials;

  RestaurantProfileData({
    required this.restaurantId,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.upiId,
    required this.fssaiNumber,
    required this.address,
    required this.costForTwo,
    required this.cuisines,
    required this.lunchOpen,
    required this.lunchClose,
    required this.dinnerOpen,
    required this.dinnerClose,
    required this.isVegOnly,
    required this.hasBar,
    required this.isAc,
    required this.parkingAvailable,
    this.dynamicDiscountEnabled = false,
    this.minDiscount = 10,
    this.maxDiscount = 30,
    this.activeOffers = const [],
    this.managerCredentials,
  });

  factory RestaurantProfileData.defaults() {
    return RestaurantProfileData(
      restaurantId: 'res_the_loaf_butter_30071',
      name: 'the loaf butter',
      ownerName: 'Amit Thakur',
      phone: '9881054788',
      email: 'amit77@gmail.com',
      upiId: 'theloafbutter@upi',
      fssaiNumber: '11521034000123',
      address: 'Shop 4, Prime High Street',
      costForTwo: 1200,
      cuisines: const ['Bakery', 'Continental'],
      lunchOpen: '11:30 AM',
      lunchClose: '03:30 PM',
      dinnerOpen: '07:00 PM',
      dinnerClose: '11:30 PM',
      isVegOnly: false,
      hasBar: false,
      isAc: true,
      parkingAvailable: true,
      dynamicDiscountEnabled: false,
      minDiscount: 10,
      maxDiscount: 30,
      activeOffers: const [], // Clean slate on new restaurant
    );
  }

  factory RestaurantProfileData.fromSupabase(Map<String, dynamic> json) {
    final owners = json['owners_details'] is Map ? json['owners_details'] as Map : {};
    final timings = json['timings'] is Map ? json['timings'] as Map : {};
    final attrs = json['attributes'] is Map ? json['attributes'] as Map : {};

    String lunchO = '11:30 AM';
    String lunchC = '03:30 PM';
    String dinnerO = '07:00 PM';
    String dinnerC = '11:30 PM';

    if (timings['lunch'] is Map) {
      lunchO = timings['lunch']['open'] ?? lunchO;
      lunchC = timings['lunch']['close'] ?? lunchC;
    }
    if (timings['dinner'] is Map) {
      dinnerO = timings['dinner']['open'] ?? dinnerO;
      dinnerC = timings['dinner']['close'] ?? dinnerC;
    }

    final cuisinesList = json['cuisines'] is List
        ? List<String>.from(json['cuisines'].map((e) => e.toString()))
        : <String>['North Indian'];

    final offersList = json['active_offers'] is List
        ? List<Map<String, dynamic>>.from(
            (json['active_offers'] as List).map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];

    final dynamicMap = attrs['dynamic_discount'] is Map ? attrs['dynamic_discount'] as Map : null;
    final dynEnabled = attrs['dynamic_discount_enabled'] == true || (dynamicMap != null && dynamicMap['enabled'] == true);
    final minD = ((attrs['min_discount'] ?? dynamicMap?['min_discount'] ?? 10) as num).toInt();
    final maxD = ((attrs['max_discount'] ?? dynamicMap?['max_discount'] ?? 30) as num).toInt();

    return RestaurantProfileData(
      restaurantId: json['restaurant_id']?.toString() ?? 'res_bombay_brasserie_01',
      name: json['name']?.toString() ?? 'BookNBytes Restaurant',
      ownerName: owners['owner_name']?.toString() ?? 'Restaurant Owner',
      phone: owners['phone']?.toString() ?? '+91 98765 43210',
      email: owners['email']?.toString() ?? 'owner@booknbytes.app',
      upiId: json['upi_id']?.toString() ?? 'restaurant@upi',
      fssaiNumber: json['fssai_number']?.toString() ?? '11521034000123',
      address: json['address']?.toString() ?? 'Prime High Street, Central District',
      costForTwo: (json['cost_for_two'] as num?)?.toInt() ?? 1200,
      cuisines: cuisinesList,
      lunchOpen: lunchO,
      lunchClose: lunchC,
      dinnerOpen: dinnerO,
      dinnerClose: dinnerC,
      isVegOnly: attrs['pure_veg'] == true,
      hasBar: attrs['serves_alcohol'] == true,
      isAc: attrs['has_ac'] ?? true,
      parkingAvailable: attrs['has_parking'] ?? true,
      dynamicDiscountEnabled: dynEnabled,
      minDiscount: minD,
      maxDiscount: maxD,
      activeOffers: offersList,
      managerCredentials: owners['manager_credentials'] is Map
          ? Map<String, dynamic>.from(owners['manager_credentials'])
          : null,
    );
  }

  Map<String, dynamic> toSupabaseUpdate() {
    return {
      'name': name,
      'upi_id': upiId,
      'fssai_number': fssaiNumber,
      'address': address,
      'cost_for_two': costForTwo,
      'cuisines': cuisines,
      'dynamic_discount_enabled': dynamicDiscountEnabled,
      'min_discount': minDiscount,
      'max_discount': maxDiscount,
      'timings': {
        'lunch': {'open': lunchOpen, 'close': lunchClose},
        'dinner': {'open': dinnerOpen, 'close': dinnerClose},
      },
      'attributes': {
        'pure_veg': isVegOnly,
        'serves_alcohol': hasBar,
        'has_ac': isAc,
        'has_parking': parkingAvailable,
        'dynamic_discount_enabled': dynamicDiscountEnabled,
        'min_discount': minDiscount,
        'max_discount': maxDiscount,
        'dynamic_discount': {
          'enabled': dynamicDiscountEnabled,
          'min_discount': minDiscount,
          'max_discount': maxDiscount,
        },
      },
      'active_offers': activeOffers,
    };
  }

  RestaurantProfileData copyWith({
    String? restaurantId,
    String? name,
    String? ownerName,
    String? phone,
    String? email,
    String? upiId,
    String? fssaiNumber,
    String? address,
    int? costForTwo,
    List<String>? cuisines,
    String? lunchOpen,
    String? lunchClose,
    String? dinnerOpen,
    String? dinnerClose,
    bool? isVegOnly,
    bool? hasBar,
    bool? isAc,
    bool? parkingAvailable,
    bool? dynamicDiscountEnabled,
    int? minDiscount,
    int? maxDiscount,
    List<Map<String, dynamic>>? activeOffers,
    Map<String, dynamic>? managerCredentials,
  }) {
    return RestaurantProfileData(
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      upiId: upiId ?? this.upiId,
      fssaiNumber: fssaiNumber ?? this.fssaiNumber,
      address: address ?? this.address,
      costForTwo: costForTwo ?? this.costForTwo,
      cuisines: cuisines ?? List.from(this.cuisines),
      lunchOpen: lunchOpen ?? this.lunchOpen,
      lunchClose: lunchClose ?? this.lunchClose,
      dinnerOpen: dinnerOpen ?? this.dinnerOpen,
      dinnerClose: dinnerClose ?? this.dinnerClose,
      isVegOnly: isVegOnly ?? this.isVegOnly,
      hasBar: hasBar ?? this.hasBar,
      isAc: isAc ?? this.isAc,
      parkingAvailable: parkingAvailable ?? this.parkingAvailable,
      dynamicDiscountEnabled: dynamicDiscountEnabled ?? this.dynamicDiscountEnabled,
      minDiscount: minDiscount ?? this.minDiscount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      activeOffers: activeOffers ?? List.from(this.activeOffers),
      managerCredentials: managerCredentials ?? this.managerCredentials,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _role = UserRole.owner;
  late RestaurantProfileData _profile;
  Map<String, dynamic>? _generatedManagerCredentials;

  bool get isAuthenticated => _currentUser != null;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserRole get role => _role;
  bool get isOwner => _role == UserRole.owner;
  bool get isManager => _role == UserRole.manager;
  bool get canAccessFinancials => isOwner;
  bool get canAccessAuditDocs => isOwner;
  bool get canViewUpi => isOwner;
  RestaurantProfileData get profile => _profile;
  Map<String, dynamic>? get generatedManagerCredentials => _generatedManagerCredentials;

  bool _shouldShowTutorial = false;
  bool get shouldShowTutorial => _shouldShowTutorial;
  bool get hasSeenTutorial => !_shouldShowTutorial;

  Future<bool> checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Only show if explicitly flagged during a fresh new signup
    _shouldShowTutorial = prefs.getBool('should_show_tutorial_new_signup') ?? false;
    notifyListeners();
    return _shouldShowTutorial;
  }

  Future<void> markTutorialSeen() async {
    _shouldShowTutorial = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('should_show_tutorial_new_signup', false);
      if (currentRestaurantId.isNotEmpty) {
        await prefs.setBool('has_seen_tutorial_$currentRestaurantId', true);
      }
      await prefs.setBool('has_seen_tutorial_global', true);
    } catch (e) {
      debugPrint('Error saving tutorial state: $e');
    }
  }

  Future<void> flagNewSignupTutorial() async {
    _shouldShowTutorial = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('should_show_tutorial_new_signup', true);
    } catch (e) {
      debugPrint('Error flagging tutorial: $e');
    }
  }

  String get currentRestaurantId => _profile.restaurantId;
  String get currentRestaurantName => _profile.name;
  String get userRole => _currentUser?.appMetadata['role']?.toString() ?? 'restaurant_owner';

  AuthProvider({bool checkAuth = true}) {
    _profile = RestaurantProfileData.defaults();
    if (checkAuth) {
      _checkInitialAuth();
    }
  }

  Future<void> _checkInitialAuth() async {
    _currentUser = _supabaseService.currentUser;
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('user_role');
      if (savedRole == 'manager' || (_currentUser?.email?.startsWith('manager.') ?? false)) {
        _role = UserRole.manager;
      } else {
        _role = UserRole.owner;
      }
      await refreshRestaurantData();
      await checkTutorialStatus();
    }
  }

  // ==========================================
  // 1. SIGN IN WITH EMAIL & PASSWORD
  // ==========================================
  Future<bool> login(
    String email,
    String password, {
    UserRole intendedRole = UserRole.owner,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _supabaseService.signInWithEmail(
        email: email.trim(),
        password: password,
      );
      _currentUser = res.user;

      final trimmedEmail = email.trim().toLowerCase();
      if (intendedRole == UserRole.manager || trimmedEmail.startsWith('manager.')) {
        _role = UserRole.manager;
      } else {
        _role = UserRole.owner;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', _role == UserRole.manager ? 'manager' : 'owner');

      await refreshRestaurantData();
      await checkTutorialStatus();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 2. SIGN UP OWNER & REGISTER RESTAURANT
  // ==========================================
  Future<bool> signupOwnerAndRegisterRestaurant({
    required String ownerName,
    required String email,
    required String password,
    required String phone,
    required String restaurantName,
    required String address,
    required String fssaiNumber,
    required String upiId,
    required int costForTwo,
    required List<String> cuisines,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _generatedManagerCredentials = null;
    notifyListeners();

    try {
      // Step 1: Call Edge Function signup-owner
      final signupResult = await _supabaseService.signupOwner(
        name: ownerName,
        email: email,
        password: password,
        phone: phone,
      );

      final ownerUser = signupResult['user'] as Map<String, dynamic>?;
      final ownerId = ownerUser?['id']?.toString() ?? '';

      // Step 2: Sign in to establish active session
      final loginRes = await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      _currentUser = loginRes.user;

      // Step 3: Create Restaurant record in Supabase
      final cleanSlug = restaurantName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final restId = 'res_${cleanSlug}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      final newRestData = {
        'restaurant_id': restId,
        'name': restaurantName,
        'upi_id': upiId,
        'fssai_number': fssaiNumber,
        'address': address,
        'cost_for_two': costForTwo,
        'cuisines': cuisines,
        'timings': {
          'lunch': {'open': '11:30 AM', 'close': '03:30 PM'},
          'dinner': {'open': '07:00 PM', 'close': '11:30 PM'},
        },
        'attributes': {
          'has_ac': true,
          'pure_veg': false,
          'has_parking': true,
          'serves_alcohol': true,
          'outdoor_seating': true,
        },
        'active_offers': <Map<String, dynamic>>[], // Start clean slate
        'rating': {'average': 4.8, 'total_reviews': 0},
        'status': 'ACTIVE',
        'owners_details': {
          'owner_id': ownerId,
          'owner_name': ownerName,
          'email': email,
          'phone': phone,
        },
      };

      await _supabaseService.createRestaurant(newRestData);

      _role = UserRole.owner;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', 'owner');

      // Step 4: Call activate-restaurant Edge Function to ensure Manager Credentials generate
      try {
        final actResult = await _supabaseService.activateRestaurant(
          restaurantId: restId,
          authToken: loginRes.session?.accessToken,
        );
        final restObj = actResult['restaurant'] as Map<String, dynamic>?;
        if (restObj != null && restObj['manager_credentials'] != null) {
          _generatedManagerCredentials = Map<String, dynamic>.from(restObj['manager_credentials']);
        }
      } catch (e) {
        debugPrint('Activation edge function notice: $e');
      }

      // Step 5: Refresh restaurant profile state
      await refreshRestaurantData();

      // Flag tutorial to display ONLY for this newly signed up restaurant
      await flagNewSignupTutorial();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 3. REFRESH RESTAURANT DATA FROM DB
  // ==========================================
  Future<void> refreshRestaurantData() async {
    try {
      final restMap = await _supabaseService.fetchRestaurantForCurrentUser();
      if (restMap != null) {
        _profile = RestaurantProfileData.fromSupabase(restMap);
        if (_profile.managerCredentials != null) {
          _generatedManagerCredentials ??= _profile.managerCredentials;
        }
        OneSignalService().loginRestaurant(_profile.restaurantId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching restaurant data: $e');
    }
  }

  // ==========================================
  // 4. UPDATE RESTAURANT PROFILE IN DB
  // ==========================================
  Future<bool> updateProfile(RestaurantProfileData updated) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateRestaurant(
        updated.restaurantId,
        updated.toSupabaseUpdate(),
      );
      _profile = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Update dynamic surprise discount range (min & max discount)
  Future<bool> updateDynamicDiscount({
    required bool enabled,
    required int minDiscount,
    required int maxDiscount,
  }) async {
    final updated = _profile.copyWith(
      dynamicDiscountEnabled: enabled,
      minDiscount: minDiscount,
      maxDiscount: maxDiscount,
    );
    return await updateProfile(updated);
  }

  // ==========================================
  // 5. UPDATE MANAGER PASSWORD (EDGE FUNCTION)
  // ==========================================
  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateManagerPassword(newPassword: newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 6. LOGOUT
  // ==========================================
  Future<void> logout() async {
    await OneSignalService().logout();
    await _supabaseService.signOut();
    _currentUser = null;
    _generatedManagerCredentials = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
    } catch (_) {}
    notifyListeners();
  }
}
