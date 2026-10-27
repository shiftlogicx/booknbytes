import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/firebase_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseConfig.initialize();
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
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Book & Bite Partner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
