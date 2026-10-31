import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/firebase_config.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/slots_provider.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'services/onesignal_service.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Client
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization note: $e');
  }

  // Only initialize Firebase if valid credentials are present
  if (FirebaseConfig.isConfigured) {
    try {
      await FirebaseConfig.initialize();
      await FCMService().initialize();
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  // Initialize notification and ringing audio systems
  try {
    await NotificationService().initialize();
    await OneSignalService().initialize();
  } catch (e) {
    debugPrint('Notification & OneSignal initialization notice: $e');
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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<NotificationProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (_, notifProvider, bookingProvider) {
            final bp = bookingProvider ?? BookingProvider();
            bp.onNewBookingAlert = (booking) {
              notifProvider.triggerIncomingBookingAlert(booking);
            };
            return bp;
          },
        ),
        ChangeNotifierProvider(create: (_) => SlotsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'BookNBytes Restaurant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
