import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for Book & Bite app.
/// Replace these placeholder values with your actual Firebase project config
/// obtained from the Firebase Console or `flutterfire configure`.
class FirebaseConfig {
  FirebaseConfig._();

  static FirebaseOptions get currentPlatformOptions {
    return const FirebaseOptions(
      apiKey: 'YOUR_API_KEY',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
      projectId: 'YOUR_PROJECT_ID',
      storageBucket: 'YOUR_STORAGE_BUCKET',
      iosBundleId: 'com.booknbite.hotel',
      androidClientId: 'YOUR_ANDROID_CLIENT_ID',
    );
  }

  /// Initialize Firebase with platform-specific options
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: currentPlatformOptions,
    );
  }
}
