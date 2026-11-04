import 'dart:ui';
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
import 'services/app_logger.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Framework-level Error Logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'FLUTTER_FRAMEWORK',
      details.exceptionAsString(),
      stackTrace: details.stack,
      details: {'context': details.context?.toString()},
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.error(
      'ASYNC_UNCAUGHT',
      error.toString(),
      stackTrace: stack,
    );
    return true;
  };

  // Initialize Supabase Client
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    AppLogger.info('DATABASE', 'Supabase initialized successfully');
  } catch (e, st) {
    AppLogger.error('DATABASE', 'Supabase initialization failure', error: e, stackTrace: st);
    debugPrint('Supabase initialization note: $e');
  }

  // Only initialize Firebase if valid credentials are present
  if (FirebaseConfig.isConfigured) {
    try {
      await FirebaseConfig.initialize();
      await FCMService().initialize();
      AppLogger.info('FCM', 'Firebase Cloud Messaging initialized');
    } catch (e, st) {
      AppLogger.error('FCM', 'Firebase initialization error', error: e, stackTrace: st);
      debugPrint('Firebase initialization notice: $e');
    }
  }

  // Initialize notification and ringing audio systems
  try {
    await NotificationService().initialize();
    await OneSignalService().initialize();
    AppLogger.info('NOTIFICATIONS', 'Notification & OneSignal engines initialized');
  } catch (e, st) {
    AppLogger.error('NOTIFICATIONS', 'Notification service error', error: e, stackTrace: st);
    debugPrint('Notification & OneSignal initialization notice: $e');
  }

  AppLogger.info('LIFECYCLE', 'Book & Bite Partner app starting root widget');
  runApp(const BookAndBiteHotelApp());
}

class BookAndBiteHotelApp extends StatefulWidget {
  const BookAndBiteHotelApp({super.key});

  @override
  State<BookAndBiteHotelApp> createState() => _BookAndBiteHotelAppState();
}

class _BookAndBiteHotelAppState extends State<BookAndBiteHotelApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure background keep-alive is active
    NotificationService().startBackgroundKeepAlive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.info('LIFECYCLE', 'State changed: ${state.name}');
    debugPrint('[AppLifecycle] State changed: $state');
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      // Screen locked or app in background: keep alive the audio session & WebSocket
      NotificationService().startBackgroundKeepAlive();
    } else if (state == AppLifecycleState.resumed) {
      // App brought back to foreground
      NotificationService().resumeBackgroundKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (_, authProvider, notifProvider, bookingProvider) {
            final bp = bookingProvider ?? BookingProvider();
            bp.onNewBookingAlert = (booking) {
              notifProvider.triggerIncomingBookingAlert(booking);
            };
            if (authProvider.currentRestaurantId.isNotEmpty) {
              bp.initForRestaurant(authProvider.currentRestaurantId);
              OneSignalService().loginRestaurant(authProvider.currentRestaurantId);
            }
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
