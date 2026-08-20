import 'package:flutter/material.dart';
import 'admin/screens/admin_login_screen.dart';
import 'services/realtime_service.dart';
import 'theme/app_theme.dart';

/// Control room / admin app entry point. Run with:
///   flutter run -t lib/main_admin.dart -d chrome
void main() {
  runApp(const WoSafarAdminApp());
}

class WoSafarAdminApp extends StatefulWidget {
  const WoSafarAdminApp({super.key});

  @override
  State<WoSafarAdminApp> createState() => _WoSafarAdminAppState();
}

class _WoSafarAdminAppState extends State<WoSafarAdminApp> {
  @override
  void initState() {
    super.initState();
    RealtimeService.instance.connect('admin');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saika — Control Room',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const AdminLoginScreen(),
    );
  }
}
