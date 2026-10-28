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
      apiKey: 'YOUR_API_KEY',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
      projectId: 'YOUR_PROJECT_ID',
      storageBucket: 'YOUR_STORAGE_BUCKET',
      iosBundleId: 'com.amitthakur.booknbite.hotelApp',
      androidClientId: 'YOUR_ANDROID_CLIENT_ID',
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
