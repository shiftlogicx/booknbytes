import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'config/firebase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/notification_provider.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: FirebaseConfig.apiKey,
        appId: FirebaseConfig.appId,
        messagingSenderId: FirebaseConfig.messagingSenderId,
        projectId: FirebaseConfig.projectId,
        storageBucket: FirebaseConfig.storageBucket,
      ),
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e (running with local test fallback)');
  }

  // Initialize notification and FCM ringing systems
  try {
    await NotificationService().initialize();
    await FCMService().initialize();
  } catch (e) {
    debugPrint('Notification service initialization notice: $e');
  }

  runApp(const BookAndBiteHotelApp());
}

class BookAndBiteHotelApp extends StatelessWidget {
  const BookAndBiteHotelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Book & Bite Hotel Terminal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1E293B),
            secondary: Colors.orangeAccent,
            surface: Color(0xFF1E293B),
          ),
          fontFamily: 'sans-serif',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
