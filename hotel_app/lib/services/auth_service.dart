import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/firebase_config.dart';
import '../models/restaurant_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Current authenticated user
  User? get currentUser => FirebaseConfig.isConfigured ? _auth.currentUser : null;

  /// Auth state stream
  Stream<User?> get authStateChanges =>
      FirebaseConfig.isConfigured ? _auth.authStateChanges() : const Stream.empty();

  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get restaurant data for the current user
  /// Assumes the user's UID maps to a restaurant document
  Future<RestaurantModel?> getRestaurantForUser(String uid) async {
    try {
      // First, try to find restaurant where owner_uid matches
      final query = await _firestore
          .collection('restaurants')
          .where('owner_uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return RestaurantModel.fromFirestore(query.docs.first);
      }

      // Fallback: try to get restaurant document with UID as document ID
      final doc = await _firestore.collection('restaurants').doc(uid).get();
      if (doc.exists) {
        return RestaurantModel.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('Error fetching restaurant: $e');
      return null;
    }
  }

  /// Store device token for FCM
  Future<void> storeDeviceToken(String restaurantId, String token) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('device_tokens')
        .doc(token)
        .set({
      'token': token,
      'created_at': FieldValue.serverTimestamp(),
      'platform': _getPlatform(),
    });
  }

  /// Remove device token on logout
  Future<void> removeDeviceToken(String restaurantId, String token) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('device_tokens')
        .doc(token)
        .delete();
  }

  String _getPlatform() {
    return 'flutter';
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
