import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'config/firebase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (FirebaseConfig.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: FirebaseConfig.platformOptions,
      );
    } catch (e) {
      debugPrint('Firebase initialization notice: $e (using local mock fallback)');
    }
  } else {
    debugPrint('[FirebaseConfig] Placeholder Firebase credentials detected. App running in offline mock mode.');
  }

  runApp(const BookAndBiteCustomerApp());
}

class BookAndBiteCustomerApp extends StatelessWidget {
  const BookAndBiteCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'Book & Bite - Diners',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
