import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'screens/splash_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/realtime_service.dart';
import 'theme/app_theme.dart';

void main() {
  if (!kIsWeb) FlutterForegroundTask.initCommunicationPort();
  BackgroundService.init();
  runApp(const WoSafarApp());
}

class WoSafarApp extends StatefulWidget {
  const WoSafarApp({super.key});

  @override
  State<WoSafarApp> createState() => _WoSafarAppState();
}

class _WoSafarAppState extends State<WoSafarApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.init();
    RealtimeService.instance.connect('rider');
    BackgroundService.start(
      title: 'Saika is running',
      text: 'Staying connected so ride updates arrive live.',
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
      title: 'Saika — Rider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
