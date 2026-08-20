import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'driver/screens/driver_splash_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/realtime_service.dart';
import 'theme/app_theme.dart';

/// Driver app entry point. Run with:
///   flutter run -t lib/main_driver.dart -d chrome
void main() {
  if (!kIsWeb) FlutterForegroundTask.initCommunicationPort();
  BackgroundService.init();
  runApp(const WoSafarDriverApp());
}

class WoSafarDriverApp extends StatefulWidget {
  const WoSafarDriverApp({super.key});

  @override
  State<WoSafarDriverApp> createState() => _WoSafarDriverAppState();
}

class _WoSafarDriverAppState extends State<WoSafarDriverApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.init();
    RealtimeService.instance.connect('driver');
    BackgroundService.start(
      title: 'Saika Driver — online',
      text: 'Staying connected so ride requests arrive live.',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      RealtimeService.instance.reconnectNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saika — Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const DriverSplashScreen(),
    );
  }
}
