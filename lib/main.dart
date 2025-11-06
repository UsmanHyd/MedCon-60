import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medcon30/splash_screen.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/theme_provider.dart' as theme;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:medcon30/services/sos_background_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void setupForegroundNotifications() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance',
            importance: Importance.max,
          ),
        ),
      );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.requestPermission();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Set up foreground notification handling
  setupForegroundNotifications();

  // Initialize SOS background service (wrapped in try-catch for graceful failure)
  try {
    await initializeSOSBackgroundService();
    print('✅ Background service initialized successfully');
  } catch (e) {
    print('⚠️ Background service initialization failed: $e');
    print('   App will continue, but background SOS countdown may not work');
    // App continues without background service - regular timer will still work
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider_pkg.ChangeNotifierProvider<theme.ThemeProvider>(
      create: (_) => theme.ThemeProvider(),
      child: provider_pkg.Consumer<theme.ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ProviderScope(
            // ADD THIS - Riverpod wrapper
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'MedCon',
              theme: ThemeData(
                primaryColor: const Color(0xFF0288D1),
                brightness: themeProvider.isDarkMode
                    ? Brightness.dark
                    : Brightness.light,
                scaffoldBackgroundColor:
                    themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
                cardColor: themeProvider.isDarkMode
                    ? const Color(0xFF222328)
                    : Colors.white,
                appBarTheme: AppBarTheme(
                  backgroundColor: themeProvider.isDarkMode
                      ? Colors.grey[850]
                      : Colors.white,
                  foregroundColor: const Color(0xFF0288D1),
                  elevation: 0,
                ),
              ),
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
