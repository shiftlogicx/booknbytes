import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for BookNBytes app.
/// Replace these placeholder values with your actual Firebase project config
/// obtained from the Firebase Console or `flutterfire configure`.
class FirebaseConfig {
  FirebaseConfig._();

  static bool get isConfigured =>
      currentPlatformOptions.apiKey != 'YOUR_API_KEY' &&
      currentPlatformOptions.appId != 'YOUR_APP_ID' &&
      !currentPlatformOptions.appId.startsWith('YOUR_');

  static FirebaseOptions get currentPlatformOptions {
    return const FirebaseOptions(
      apiKey: 'AIzaSyBDfEB54psVBhLW_qoPxIAA_-CleEmO6Ew',
      appId: '1:480656946997:android:72df0497a3ed0d0c62fe7c',
      messagingSenderId: '480656946997',
      projectId: 'booknbytes',
      storageBucket: 'booknbytes.firebasestorage.app',
      androidClientId: '480656946997-d86b6a.apps.googleusercontent.com',
    );
  }

  /// Initialize Firebase with platform-specific options
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint('[FirebaseConfig] Placeholder Firebase credentials detected. App running in offline mock mode.');
      return;
    }
    await Firebase.initializeApp(
      options: currentPlatformOptions,
    );
  }
}
