import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../services/supabase_service.dart';
import '../services/onesignal_service.dart';
import '../services/app_logger.dart';

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
  String breakfastOpen;
  String breakfastClose;
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
  String mainPhoto;
  List<String> subordinatePhotos;
  List<String> menuImages;

  List<String> get hotelPhotos => [if (mainPhoto.isNotEmpty) mainPhoto, ...subordinatePhotos];
  int get totalPhotosCount => (mainPhoto.isNotEmpty ? 1 : 0) + subordinatePhotos.length;
  bool get canAddSubordinatePhoto => subordinatePhotos.length < 2 && totalPhotosCount < 3;
  bool get hasMainPhoto => mainPhoto.trim().isNotEmpty;

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
    required this.breakfastOpen,
    required this.breakfastClose,
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
    this.mainPhoto = '',
    this.subordinatePhotos = const [],
    List<String>? hotelPhotos,
    this.menuImages = const [],
  }) {
    if (hotelPhotos != null && hotelPhotos.isNotEmpty && mainPhoto.isEmpty && subordinatePhotos.isEmpty) {
      mainPhoto = hotelPhotos.first;
      subordinatePhotos = hotelPhotos.skip(1).take(2).toList();
    }
  }

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
      breakfastOpen: '07:30 AM',
      breakfastClose: '11:00 AM',
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
      mainPhoto: '',
      subordinatePhotos: const [],
      menuImages: const [],
    );
  }

  factory RestaurantProfileData.fromSupabase(Map<String, dynamic> json) {
    final owners = json['owners_details'] is Map ? json['owners_details'] as Map : {};
    final timings = json['timings'] is Map ? json['timings'] as Map : {};
    final attrs = json['attributes'] is Map ? json['attributes'] as Map : {};
    final visuals = json['visuals'] is Map ? json['visuals'] as Map : {};

    String heroImg = visuals['hero_image']?.toString() ?? '';
    final rawAmbience = visuals['ambience'] is List
        ? List<String>.from((visuals['ambience'] as List).map((e) => e.toString()))
        : <String>[];

    if (heroImg.isEmpty && rawAmbience.isNotEmpty) {
      heroImg = rawAmbience.first;
      rawAmbience.removeAt(0);
    } else {
      rawAmbience.removeWhere((url) => url == heroImg);
    }
    final subPhotosList = rawAmbience.take(2).toList();

    final menuImagesList = visuals['menu_images'] is List
        ? List<String>.from((visuals['menu_images'] as List).map((e) => e.toString()))
        : <String>[];

    String breakfastO = '07:30 AM';
    String breakfastC = '11:00 AM';
    String lunchO = '11:30 AM';
    String lunchC = '03:30 PM';
    String dinnerO = '07:00 PM';
    String dinnerC = '11:30 PM';

    if (timings['breakfast'] is Map) {
      breakfastO = timings['breakfast']['open'] ?? breakfastO;
      breakfastC = timings['breakfast']['close'] ?? breakfastC;
    }
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
      breakfastOpen: breakfastO,
      breakfastClose: breakfastC,
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
      mainPhoto: heroImg,
      subordinatePhotos: subPhotosList,
      menuImages: menuImagesList,
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
        'breakfast': {'open': breakfastOpen, 'close': breakfastClose},
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
      'visuals': {
        'hero_image': mainPhoto,
        'ambience': subordinatePhotos.take(2).toList(),
        'menu_images': menuImages,
      },
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
    String? breakfastOpen,
    String? breakfastClose,
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
    String? mainPhoto,
    List<String>? subordinatePhotos,
    List<String>? hotelPhotos,
    List<String>? menuImages,
  }) {
    String resolvedMain = mainPhoto ?? this.mainPhoto;
    List<String> resolvedSubs = subordinatePhotos != null ? List<String>.from(subordinatePhotos) : List<String>.from(this.subordinatePhotos);

    if (hotelPhotos != null) {
      if (hotelPhotos.isNotEmpty) {
        resolvedMain = hotelPhotos.first;
        resolvedSubs = hotelPhotos.skip(1).take(2).toList();
      } else {
        resolvedMain = '';
        resolvedSubs = [];
      }
    }

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
      breakfastOpen: breakfastOpen ?? this.breakfastOpen,
      breakfastClose: breakfastClose ?? this.breakfastClose,
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
      mainPhoto: resolvedMain,
      subordinatePhotos: resolvedSubs,
      menuImages: menuImages ?? List.from(this.menuImages),
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

    AppLogger.info('AUTH', 'Login attempt', details: {'email': email.trim(), 'role': intendedRole.name});

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
      if (_role == UserRole.owner) {
        await prefs.setString('last_owner_email', email.trim());
      } else {
        await prefs.setString('last_manager_email', email.trim());
      }

      await refreshRestaurantData();
      await checkTutorialStatus();

      AppLogger.setActiveContext(restaurantId: currentRestaurantId, userId: _currentUser?.id);
      AppLogger.info('AUTH', 'Login successful', details: {
        'email': email.trim(),
        'role': _role.name,
        'restaurant_id': currentRestaurantId,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('AUTH', 'Login failed', error: e, stackTrace: st, details: {'email': email.trim()});
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // PASSWORD RESET & RECOVERY (SUPABASE AUTH)
  // ==========================================
  Future<Map<String, dynamic>?> requestPasswordRecoveryCode(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    AppLogger.info('AUTH', 'Password recovery requested', details: {'email': email.trim()});
    try {
      final res = await _supabaseService.generatePasswordRecoveryCode(email);
      AppLogger.info('AUTH', 'Recovery code generated & dispatched', details: {'email': email.trim()});
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e, st) {
      AppLogger.error('AUTH', 'Password recovery failed', error: e, stackTrace: st, details: {'email': email.trim()});
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePasswordAfterRecovery({
    required String userId,
    required String newPassword,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    AppLogger.info('AUTH', 'Password reset execution started', details: {'email': email, 'userId': userId});
    try {
      await _supabaseService.adminUpdatePassword(
        userId: userId,
        newPassword: newPassword,
        email: email,
      );
      AppLogger.info('AUTH', 'Password reset completed successfully', details: {'email': email, 'userId': userId});
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('AUTH', 'Password reset failed', error: e, stackTrace: st, details: {'email': email});
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabaseService.sendPasswordResetEmail(email);
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

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final authRes = await _supabaseService.verifyRecoveryOtp(email: email, token: otp);
      if (authRes.session == null && authRes.user == null) {
        throw Exception('Invalid or expired verification code.');
      }
      await _supabaseService.updateUserPassword(newPassword);
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

  Future<Map<String, dynamic>?> checkManagerRestaurant(String managerEmail) async {
    return await _supabaseService.findRestaurantByManagerEmail(managerEmail);
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
    double? latitude,
    double? longitude,
    Uint8List? onboardingMainPhotoBytes,
    String? onboardingMainPhotoFilename,
    List<Map<String, dynamic>>? onboardingSubordinatePhotos,
    List<Map<String, dynamic>>? onboardingMenuImages,
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
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      final restId = 'res_${cleanSlug}_$uniqueSuffix';
      final cleanEmailSlug = restaurantName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      // Generate 100% unique credentials per restaurant onboarding
      final random = Random();
      final randPin = (1000 + random.nextInt(9000)).toString();
      const passChars = 'abcdefghjkmnpqrstuvwxyz23456789';
      final randPassToken = List.generate(4, (_) => passChars[random.nextInt(passChars.length)]).join();

      final managerEmail = 'manager.${cleanEmailSlug.isEmpty ? cleanSlug : cleanEmailSlug}.$randPin@booknbytes.app';
      final defaultManagerPassword = 'Mgr@${cleanSlug.length >= 3 ? cleanSlug.substring(0, 3) : "bnb"}$randPassToken!';

      final managerCreds = {
        'email': managerEmail,
        'default_password': defaultManagerPassword,
        'created_at': DateTime.now().toIso8601String(),
      };

      final newRestData = {
        'restaurant_id': restId,
        'name': restaurantName,
        'upi_id': upiId,
        'fssai_number': fssaiNumber,
        'address': address,
        if (latitude != null && longitude != null)
          'geo_location': 'POINT($longitude $latitude)',
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
          'manager_credentials': managerCreds,
        },
      };

      await _supabaseService.createRestaurant(newRestData);

      _role = UserRole.owner;
      _generatedManagerCredentials = managerCreds;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', 'owner');
      await prefs.setString('last_owner_email', email);
      await prefs.setString('last_manager_email', managerEmail);
      await prefs.setString('last_manager_password', defaultManagerPassword);

      // Step 4: Call activate-restaurant Edge Function to ensure Manager User row is provisioned in Supabase Auth
      try {
        final actResult = await _supabaseService.activateRestaurant(
          restaurantId: restId,
          authToken: SupabaseConfig.serviceRoleKey,
        );
        final restObj = actResult['restaurant'] as Map<String, dynamic>?;
        if (restObj != null && restObj['manager_credentials'] != null) {
          _generatedManagerCredentials = Map<String, dynamic>.from(restObj['manager_credentials']);
          final pEmail = _generatedManagerCredentials!['email']?.toString();
          final pPass = _generatedManagerCredentials!['default_password']?.toString();
          if (pEmail != null) await prefs.setString('last_manager_email', pEmail);
          if (pPass != null) await prefs.setString('last_manager_password', pPass);
        }
      } catch (e) {
        debugPrint('Activation edge function notice: $e');
      }

      // Step 4.5: Upload optional onboarding photos (Main photo, subordinate photos, and menu pages)
      String uploadedMainUrl = '';
      final uploadedSubUrls = <String>[];
      final uploadedMenuUrls = <String>[];

      if (onboardingMainPhotoBytes != null) {
        try {
          uploadedMainUrl = await _supabaseService.uploadMediaFile(
            restaurantId: restId,
            category: 'hero',
            bytes: onboardingMainPhotoBytes,
            filename: onboardingMainPhotoFilename ?? 'main_hero.jpg',
          );
        } catch (e) {
          debugPrint('Onboarding main photo upload error: $e');
        }
      }

      if (onboardingSubordinatePhotos != null && onboardingSubordinatePhotos.isNotEmpty) {
        for (final item in onboardingSubordinatePhotos.take(2)) {
          try {
            final u = await _supabaseService.uploadMediaFile(
              restaurantId: restId,
              category: 'ambience',
              bytes: item['bytes'] as Uint8List,
              filename: item['filename'] as String? ?? 'subordinate.jpg',
            );
            uploadedSubUrls.add(u);
          } catch (e) {
            debugPrint('Onboarding subordinate photo upload error: $e');
          }
        }
      }

      if (onboardingMenuImages != null && onboardingMenuImages.isNotEmpty) {
        for (final item in onboardingMenuImages) {
          try {
            final u = await _supabaseService.uploadMediaFile(
              restaurantId: restId,
              category: 'menu',
              bytes: item['bytes'] as Uint8List,
              filename: item['filename'] as String? ?? 'menu_page.jpg',
            );
            uploadedMenuUrls.add(u);
          } catch (e) {
            debugPrint('Onboarding menu upload error: $e');
          }
        }
      }

      if (uploadedMainUrl.isNotEmpty || uploadedSubUrls.isNotEmpty || uploadedMenuUrls.isNotEmpty) {
        try {
          await _supabaseService.updateRestaurantVisuals(
            restaurantId: restId,
            heroImage: uploadedMainUrl,
            subordinatePhotos: uploadedSubUrls,
            menuImages: uploadedMenuUrls,
          );
        } catch (e) {
          debugPrint('Error updating onboarding visuals: $e');
        }
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
          final prefs = await SharedPreferences.getInstance();
          final pEmail = _profile.managerCredentials!['email']?.toString();
          final pPass = _profile.managerCredentials!['default_password']?.toString();
          if (pEmail != null) await prefs.setString('last_manager_email', pEmail);
          if (pPass != null) await prefs.setString('last_manager_password', pPass);
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
  // MEDIA MANAGEMENT (MAIN PHOTO, SUBORDINATE & MENUS)
  // ==========================================
  Future<bool> uploadMainPhoto(Uint8List bytes, String filename) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    AppLogger.info('STORAGE', 'Uploading main hotel photo (profile picture)', details: {'filename': filename, 'restaurant_id': currentRestaurantId});
    try {
      final url = await _supabaseService.uploadMediaFile(
        restaurantId: currentRestaurantId,
        category: 'hero',
        bytes: bytes,
        filename: filename,
      );
      final oldMain = _profile.mainPhoto;
      _profile = _profile.copyWith(mainPhoto: url);
      await _supabaseService.updateRestaurantVisuals(
        restaurantId: currentRestaurantId,
        heroImage: _profile.mainPhoto,
        subordinatePhotos: _profile.subordinatePhotos,
        menuImages: _profile.menuImages,
      );
      if (oldMain.isNotEmpty && oldMain != url) {
        _supabaseService.deleteMediaFile(oldMain).catchError((_) {});
      }
      AppLogger.info('STORAGE', 'Main photo updated successfully', details: {'url': url});
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('STORAGE', 'Main photo upload failed', error: e, stackTrace: st, details: {'filename': filename});
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadSubordinatePhoto(Uint8List bytes, String filename) async {
    if (_profile.subordinatePhotos.length >= 2 || _profile.totalPhotosCount >= 3) {
      _errorMessage = 'Maximum 2 subordinate photos allowed (3 photos total with Main Photo).';
      AppLogger.warn('STORAGE', 'Subordinate photo limit reached', details: {'restaurant_id': currentRestaurantId});
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    AppLogger.info('STORAGE', 'Uploading subordinate photo', details: {'filename': filename, 'restaurant_id': currentRestaurantId});
    try {
      final url = await _supabaseService.uploadMediaFile(
        restaurantId: currentRestaurantId,
        category: 'ambience',
        bytes: bytes,
        filename: filename,
      );
      final updatedSubs = List<String>.from(_profile.subordinatePhotos)..add(url);
      _profile = _profile.copyWith(subordinatePhotos: updatedSubs.take(2).toList());
      await _supabaseService.updateRestaurantVisuals(
        restaurantId: currentRestaurantId,
        heroImage: _profile.mainPhoto,
        subordinatePhotos: _profile.subordinatePhotos,
        menuImages: _profile.menuImages,
      );
      AppLogger.info('STORAGE', 'Subordinate photo upload success', details: {'url': url, 'count': _profile.subordinatePhotos.length});
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('STORAGE', 'Subordinate photo upload failed', error: e, stackTrace: st, details: {'filename': filename});
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> setAsMainPhoto(String photoUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    AppLogger.info('STORAGE', 'Promoting photo to main profile photo', details: {'url': photoUrl});
    try {
      final oldMain = _profile.mainPhoto;
      final updatedSubs = List<String>.from(_profile.subordinatePhotos)..remove(photoUrl);
      if (oldMain.isNotEmpty && oldMain != photoUrl && updatedSubs.length < 2) {
        updatedSubs.insert(0, oldMain);
      }
      _profile = _profile.copyWith(
        mainPhoto: photoUrl,
        subordinatePhotos: updatedSubs.take(2).toList(),
      );
      await _supabaseService.updateRestaurantVisuals(
        restaurantId: currentRestaurantId,
        heroImage: _profile.mainPhoto,
        subordinatePhotos: _profile.subordinatePhotos,
        menuImages: _profile.menuImages,
      );
      AppLogger.info('STORAGE', 'Photo set as main successfully', details: {'main': photoUrl});
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('STORAGE', 'Failed to promote to main photo', error: e, stackTrace: st);
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMainPhoto() async {
    if (_profile.mainPhoto.isEmpty) return true;
    final urlToDelete = _profile.mainPhoto;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      String newMain = '';
      List<String> newSubs = List<String>.from(_profile.subordinatePhotos);
      if (newSubs.isNotEmpty) {
        newMain = newSubs.removeAt(0);
      }
      _profile = _profile.copyWith(
        mainPhoto: newMain,
        subordinatePhotos: newSubs,
      );
      await _supabaseService.updateRestaurantVisuals(
        restaurantId: currentRestaurantId,
        heroImage: _profile.mainPhoto,
        subordinatePhotos: _profile.subordinatePhotos,
        menuImages: _profile.menuImages,
      );
      await _supabaseService.deleteMediaFile(urlToDelete);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('STORAGE', 'Failed to delete main photo', error: e, stackTrace: st);
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSubordinatePhoto(String photoUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedSubs = List<String>.from(_profile.subordinatePhotos)..remove(photoUrl);
      _profile = _profile.copyWith(subordinatePhotos: updatedSubs);
      await _supabaseService.updateRestaurantVisuals(
        restaurantId: currentRestaurantId,
        heroImage: _profile.mainPhoto,
        subordinatePhotos: _profile.subordinatePhotos,
        menuImages: _profile.menuImages,
      );
      await _supabaseService.deleteMediaFile(photoUrl);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('STORAGE', 'Failed to delete subordinate photo', error: e, stackTrace: st);
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadHotelPhoto(Uint8List bytes, String filename) async {
    if (_profile.mainPhoto.isEmpty) {
      return await uploadMainPhoto(bytes, filename);
    } else {
      return await uploadSubordinatePhoto(bytes, filename);
    }
  }

  Future<bool> deleteHotelPhoto(String photoUrl) async {
    if (photoUrl == _profile.mainPhoto) {
      return await deleteMainPhoto();
    } else {
      return await deleteSubordinatePhoto(photoUrl);
    }
  }

  Future<bool> uploadMenuImage(Uint8List bytes, String filename) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    AppLogger.info('STORAGE', 'Uploading menu image page', details: {'filename': filename, 'restaurant_id': currentRestaurantId});
    try {
      final url = await _supabaseService.uploadMediaFile(
        restaurantId: currentRestaurantId,
        category: 'menu',
        bytes: bytes,
        filename: filename,
      );
      final updatedMenu = List<String>.from(_profile.menuImages)..add(url);
      _profile = _profile.copyWith(menuImages: updatedMenu);
      await _supabaseService.updateRestaurantVisuals(
        restaurantId: currentRestaurantId,
        hotelPhotos: _profile.hotelPhotos,
        menuImages: _profile.menuImages,
      );
      AppLogger.info('STORAGE', 'Menu image page upload success', details: {'url': url, 'totalPages': _profile.menuImages.length});
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('STORAGE', 'Menu image upload failed', error: e, stackTrace: st, details: {'filename': filename});
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMenuImage(String menuUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    AppLogger.info('STORAGE', 'Deleting menu image page', details: {'url': menuUrl});
    try {
      final updatedMenu = List<String>.from(_profile.menuImages)..remove(menuUrl);
      _profile = _profile.copyWith(menuImages: updatedMenu);
      await _supabaseService.updateRestaurantVisuals(
        restaurantId: currentRestaurantId,
        hotelPhotos: _profile.hotelPhotos,
        menuImages: _profile.menuImages,
      );
      await _supabaseService.deleteMediaFile(menuUrl);
      AppLogger.info('STORAGE', 'Menu image deleted successfully', details: {'url': menuUrl});
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('STORAGE', 'Menu image delete error', error: e, stackTrace: st, details: {'url': menuUrl});
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // 5. UPDATE MANAGER PASSWORD (EDGE FUNCTION)
  // ==========================================
  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateManagerPassword(newPassword: newPassword);
      AppLogger.info('AUTH', 'Manager password updated successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('AUTH', 'Manager password update failed', error: e, stackTrace: st);
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
    AppLogger.info('AUTH', 'Sign out initiated', details: {'restaurant_id': currentRestaurantId});
    await OneSignalService().logout();
    await _supabaseService.signOut();
    _currentUser = null;
    _generatedManagerCredentials = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
    } catch (_) {}
    AppLogger.info('AUTH', 'Sign out completed');
    notifyListeners();
  }
}
