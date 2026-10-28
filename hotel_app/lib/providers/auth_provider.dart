import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';

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
  });

  factory RestaurantProfileData.defaults() {
    return RestaurantProfileData(
      restaurantId: 'res_12345xyz',
      name: 'Mahesh Lunch Home',
      ownerName: 'Mahesh Shetty',
      phone: '+91 98200 87654',
      email: 'mahesh@lunchhome.com',
      upiId: 'maheshlunch@sbi',
      fssaiNumber: '11521034000123',
      address: 'Camp, Pune, Maharashtra - 411001',
      costForTwo: 1200,
      cuisines: ['Seafood', 'Mangalorean', 'North Indian', 'Coastal Curries'],
      lunchOpen: '11:30 AM',
      lunchClose: '03:30 PM',
      dinnerOpen: '07:00 PM',
      dinnerClose: '11:30 PM',
      isVegOnly: false,
      hasBar: true,
      isAc: true,
      parkingAvailable: true,
    );
  }

  factory RestaurantProfileData.fromJson(Map<String, dynamic> json) {
    return RestaurantProfileData(
      restaurantId: json['restaurant_id'] ?? 'res_12345xyz',
      name: json['name'] ?? 'Mahesh Lunch Home',
      ownerName: json['owner_name'] ?? 'Mahesh Shetty',
      phone: json['phone'] ?? '+91 98200 87654',
      email: json['email'] ?? 'mahesh@lunchhome.com',
      upiId: json['upi_id'] ?? 'maheshlunch@sbi',
      fssaiNumber: json['fssai_number'] ?? '11521034000123',
      address: json['address'] ?? 'Camp, Pune, Maharashtra - 411001',
      costForTwo: (json['cost_for_two'] as num?)?.toInt() ?? 1200,
      cuisines: List<String>.from(json['cuisines'] ?? ['Seafood', 'North Indian']),
      lunchOpen: json['lunch_open'] ?? '11:30 AM',
      lunchClose: json['lunch_close'] ?? '03:30 PM',
      dinnerOpen: json['dinner_open'] ?? '07:00 PM',
      dinnerClose: json['dinner_close'] ?? '11:30 PM',
      isVegOnly: json['is_veg_only'] ?? false,
      hasBar: json['has_bar'] ?? true,
      isAc: json['is_ac'] ?? true,
      parkingAvailable: json['parking_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurantId,
      'name': name,
      'owner_name': ownerName,
      'phone': phone,
      'email': email,
      'upi_id': upiId,
      'fssai_number': fssaiNumber,
      'address': address,
      'cost_for_two': costForTwo,
      'cuisines': cuisines,
      'lunch_open': lunchOpen,
      'lunch_close': lunchClose,
      'dinner_open': dinnerOpen,
      'dinner_close': dinnerClose,
      'is_veg_only': isVegOnly,
      'has_bar': hasBar,
      'is_ac': isAc,
      'parking_available': parkingAvailable,
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
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _currentOwner;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSeenTutorial = false;
  late RestaurantProfileData _profile;

  bool get isAuthenticated => _currentOwner != null;
  Map<String, dynamic>? get currentOwner => _currentOwner;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSeenTutorial => _hasSeenTutorial;
  RestaurantProfileData get profile => _profile;

  String get currentRestaurantId => _profile.restaurantId;
  String get currentRestaurantName => _profile.name;

  AuthProvider() {
    _profile = RestaurantProfileData.defaults();
    _initDemoOwner();
    _loadPersistedData();
  }

  void _initDemoOwner() {
    _currentOwner = {
      'uid': 'owner_123',
      'email': _profile.email,
      'restaurant_id': _profile.restaurantId,
      'name': _profile.name,
    };
  }

  Future<void> _loadPersistedData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      var file = File('${dir.path}/restaurant_profile.json');
      if (!await file.exists()) {
        final legacyFile = File('${dir.path}/partner_profile.json');
        if (await legacyFile.exists()) {
          file = legacyFile;
        }
      }
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        if (data.containsKey('profile')) {
          _profile = RestaurantProfileData.fromJson(data['profile']);
          _currentOwner?['name'] = _profile.name;
          _currentOwner?['email'] = _profile.email;
        }
        if (data.containsKey('has_seen_tutorial')) {
          _hasSeenTutorial = data['has_seen_tutorial'] == true;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading persisted restaurant profile: $e');
    }
  }

  Future<void> _savePersistedData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/restaurant_profile.json');
      final payload = {
        'profile': _profile.toJson(),
        'has_seen_tutorial': _hasSeenTutorial,
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (e) {
      debugPrint('Error saving restaurant profile: $e');
    }
  }

  Future<void> updateProfile(RestaurantProfileData updated) async {
    _profile = updated;
    if (_currentOwner != null) {
      _currentOwner!['name'] = updated.name;
      _currentOwner!['email'] = updated.email;
    }
    notifyListeners();
    await _savePersistedData();
  }

  void markTutorialSeen() {
    _hasSeenTutorial = true;
    notifyListeners();
    _savePersistedData();
  }

  void resetTutorial() {
    _hasSeenTutorial = false;
    notifyListeners();
    _savePersistedData();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _currentOwner = {
          'uid': user.uid,
          'email': email,
          'restaurant_id': _profile.restaurantId,
          'name': _profile.name,
        };
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _authService.signOut();
    _currentOwner = null;
    notifyListeners();
  }
}
