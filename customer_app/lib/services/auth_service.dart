import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    // Check if user exists in Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      // Create new user document
      final newUser = UserModel(
        userId: user.uid,
        name: user.displayName ?? '',
        phoneNumber: user.phoneNumber ?? '',
        email: user.email ?? '',
        authProvider: 'google',
        preferences: [],
        totalBookings: 0,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(newUser.toFirestore());
      return newUser;
    }

    return UserModel.fromFirestore(userDoc);
  }

  /// Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        onAutoVerify(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verify OTP and sign in
  Future<UserModel?> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    // Check if user exists in Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      final newUser = UserModel(
        userId: user.uid,
        name: user.displayName ?? 'User',
        phoneNumber: user.phoneNumber ?? '',
        email: user.email ?? '',
        authProvider: 'phone',
        preferences: [],
        totalBookings: 0,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(newUser.toFirestore());
      return newUser;
    }

    return UserModel.fromFirestore(userDoc);
  }

  /// Sign in with phone auth credential (auto-verify)
  Future<UserModel?> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      final newUser = UserModel(
        userId: user.uid,
        name: 'User',
        phoneNumber: user.phoneNumber ?? '',
        email: '',
        authProvider: 'phone',
        preferences: [],
        totalBookings: 0,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(newUser.toFirestore());
      return newUser;
    }

    return UserModel.fromFirestore(userDoc);
  }

  /// Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.userId)
        .update(user.toFirestore());
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
