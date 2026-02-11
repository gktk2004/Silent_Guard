import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/preferences_helper.dart';
import 'utils/alert_helper.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification channels (must happen before background service starts)
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
    const AndroidNotificationChannel(
      'silent_guard_service',
      'Silent Guard Service',
      description: 'Running in background',
      importance: Importance.low,
    ),
  );
  
  // Initialize helpers
  await AlertHelper.initialize();
  
  // Initialize and configure background service
  await initializeService();

  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Determine initial route based on whether phone number is set
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    // If service is already running, go to dashboard
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      setState(() {
        _home = const DashboardScreen();
      });
      return;
    }

    // Otherwise check for phone number
    final phone = await PreferencesHelper.getEmergencyNumber();
    setState(() {
      if (phone != null && phone.isNotEmpty) {
        _home = const DashboardScreen();
      } else {
        _home = const SetupScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Silent Guard',
      theme: AppTheme.lightTheme,
      home: _home ?? const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
