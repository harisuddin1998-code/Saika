import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/saika_pattern.dart';
import '../models/driver_identity.dart';
import 'driver_home_screen.dart';
import 'driver_login_screen.dart';

class DriverSplashScreen extends StatefulWidget {
  const DriverSplashScreen({super.key});

  @override
  State<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends State<DriverSplashScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    DriverIdentity.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: DriverIdentity.registered
            ? const RouteSettings(name: '/driver_home')
            : null,
        builder: (_) => DriverIdentity.registered
            ? const DriverHomeScreen()
            : const DriverLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SaikaBand(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.safe, width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/branding/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Saika', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 34)),
                    const SizedBox(height: 6),
                    Text('DRIVER', style: TextStyle(fontFamily: 'monospace', fontSize: 13, letterSpacing: 3, color: p.safe, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Text('Drive on your terms. Earn on your price.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.muted)),
                    const SizedBox(height: 8),
                    Text('Karachi, Sindh', style: TextStyle(fontSize: 11.5, color: p.muted)),
                    const SizedBox(height: 44),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: p.safe, foregroundColor: p.safeInk),
                      onPressed: _ready ? _continue : null,
                      child: _ready
                          ? const Text('Continue')
                          : const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SaikaBand(),
          ],
        ),
      ),
    );
  }
}
