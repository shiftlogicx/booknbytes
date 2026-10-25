import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _currentOwner;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _currentOwner != null;
  Map<String, dynamic>? get currentOwner => _currentOwner;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get currentRestaurantId => _currentOwner?['restaurant_id'] ?? 'res_12345xyz';
  String get currentRestaurantName => _currentOwner?['name'] ?? 'Mahesh Lunch Home';

  AuthProvider() {
    _initDemoOwner();
  }

  void _initDemoOwner() {
    // Pre-fill demo restaurant owner for immediate testing
    _currentOwner = {
      'uid': 'owner_123',
      'email': 'mahesh@lunchhome.com',
      'restaurant_id': 'res_12345xyz',
      'name': 'Mahesh Lunch Home',
    };
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.login(email, password);
      if (success) {
        _currentOwner = {
          'uid': 'owner_123',
          'email': email,
          'restaurant_id': 'res_12345xyz',
          'name': 'Mahesh Lunch Home',
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
    _currentOwner = null;
    notifyListeners();
  }
}
