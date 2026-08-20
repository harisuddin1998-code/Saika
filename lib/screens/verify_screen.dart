import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WELCOME', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.accent)),
              const SizedBox(height: 10),
              Text('Every ride, verified\nboth ways', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 28),
              _VerifyRow(text: 'CNIC-verified drivers, checked before onboarding'),
              const SizedBox(height: 18),
              _VerifyRow(text: 'Selfie match required at every driver login'),
              const SizedBox(height: 18),
              _VerifyRow(text: 'Women-only riders and drivers, by design'),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(settings: const RouteSettings(name: '/home'), builder: (_) => const HomeScreen()),
                ),
                child: const Text('Enter Saika'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifyRow extends StatelessWidget {
  final String text;
  const _VerifyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(color: p.safe, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(Icons.check, size: 13, color: p.safeInk),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
