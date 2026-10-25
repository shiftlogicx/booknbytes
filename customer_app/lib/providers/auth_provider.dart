import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _verificationId;

  AuthState get state => _state;
  UserModel? get user => _user;
  UserModel? get currentUser => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  String? get verificationId => _verificationId;

  /// Quick mock sign-in for demonstration and testing
  Future<void> signInWithMock({required String name, required String phone}) async {
    _state = AuthState.loading;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _user = UserModel(
      userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phoneNumber: phone,
      email: '${name.toLowerCase().replaceAll(' ', '')}@gmail.com',
      authProvider: 'phone',
      preferences: ['Veg', 'North Indian'],
      totalBookings: 1,
      createdAt: DateTime.now(),
    );
    _state = AuthState.authenticated;
    notifyListeners();
  }

  AuthProvider() {
    _checkAuthState();
  }

  /// Check if user is already signed in
  Future<void> _checkAuthState() async {
    _state = AuthState.loading;
    notifyListeners();

    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      try {
        _user = await _authService.getUserProfile(currentUser.uid);
        if (_user != null) {
          _state = AuthState.authenticated;
        } else {
          // User exists in Firebase Auth but not in Firestore
          // Create the profile
          _user = UserModel(
            userId: currentUser.uid,
            name: currentUser.displayName ?? 'User',
            phoneNumber: currentUser.phoneNumber ?? '',
            email: currentUser.email ?? '',
            authProvider: 'google',
            preferences: [],
            totalBookings: 0,
            createdAt: DateTime.now(),
          );
          _state = AuthState.authenticated;
        }
      } catch (e) {
        _state = AuthState.unauthenticated;
      }
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.signInWithGoogle();
      if (_user != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
        _errorMessage = 'Google sign in was cancelled';
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Failed to sign in with Google: ${e.toString()}';
    }
    notifyListeners();
  }

  /// Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _verificationId = verificationId;
          _state = AuthState.otpSent;
          notifyListeners();
        },
        onError: (error) {
          _state = AuthState.error;
          _errorMessage = error;
          notifyListeners();
        },
        onAutoVerify: (credential) async {
          await _signInWithPhoneCredential(credential);
        },
      );
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Failed to send OTP: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Verify OTP
  Future<void> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _errorMessage = 'No verification ID found. Please request OTP again.';
      _state = AuthState.error;
      notifyListeners();
      return;
    }

    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _authService.verifyOTP(
        verificationId: _verificationId!,
        otp: otp,
      );

      if (_user != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Failed to verify OTP';
      }
    } on FirebaseAuthException catch (e) {
      _state = AuthState.error;
      if (e.code == 'invalid-verification-code') {
        _errorMessage = 'Invalid OTP. Please try again.';
      } else {
        _errorMessage = e.message ?? 'Verification failed';
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Failed to verify OTP: ${e.toString()}';
    }
    notifyListeners();
  }

  /// Sign in with phone credential (auto-verify)
  Future<void> _signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    try {
      _user = await _authService.signInWithPhoneCredential(credential);
      if (_user != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Auto-verification failed';
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Auto-verification failed: ${e.toString()}';
    }
    notifyListeners();
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _state = AuthState.unauthenticated;
      _verificationId = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out: ${e.toString()}';
    }
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset to unauthenticated state (e.g., when going back from OTP screen)
  void resetToLogin() {
    _state = AuthState.unauthenticated;
    _verificationId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
