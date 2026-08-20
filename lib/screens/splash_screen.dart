import 'package:flutter/material.dart';
import '../models/rider_identity.dart';
import '../theme/app_theme.dart';
import '../widgets/saika_pattern.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    RiderIdentity.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RiderIdentity.registered
            ? const RouteSettings(name: '/home')
            : null,
        builder: (_) =>
            RiderIdentity.registered ? const HomeScreen() : const LoginScreen(),
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
                        border: Border.all(color: p.accent, width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/branding/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Saika', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 34)),
                    const SizedBox(height: 10),
                    Text(
                      'Every ride, watched over like family.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 16, color: p.inkDim),
                    ),
                    const SizedBox(height: 8),
                    Text('Women drivers. Electric cars. Karachi, Sindh.', style: TextStyle(fontSize: 12.5, color: p.muted)),
                    const SizedBox(height: 44),
                    FilledButton(
                      onPressed: _ready ? _continue : null,
                      child: _ready
                          ? const Text('Continue')
                          : const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
