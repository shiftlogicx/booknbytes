import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const String apiKey = 'YOUR_API_KEY';
  static const String authDomain = 'book-and-bite-mvp.firebaseapp.com';
  static const String projectId = 'book-and-bite-mvp';
  static const String storageBucket = 'book-and-bite-mvp.appspot.com';
  static const String messagingSenderId = 'YOUR_SENDER_ID';
  static const String appId = 'YOUR_APP_ID';

  static bool get isConfigured =>
      apiKey != 'YOUR_API_KEY' &&
      appId != 'YOUR_APP_ID' &&
      !appId.startsWith('YOUR_');

  static FirebaseOptions get platformOptions {
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }
}
