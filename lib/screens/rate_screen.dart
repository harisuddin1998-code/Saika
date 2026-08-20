import 'package:flutter/material.dart';
import '../models/active_trip.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class RateScreen extends StatelessWidget {
  final int farePaid;
  const RateScreen({super.key, required this.farePaid});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('TRIP COMPLETE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.accent)),
              const SizedBox(height: 10),
              Text('Rs $farePaid paid', style: TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.bold, color: p.ink)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (_) => Icon(Icons.star, color: p.accent, size: 30)),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  _Pill(text: 'Felt safe', on: true),
                  const _Pill(text: 'On time'),
                  const _Pill(text: 'Clean car'),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  ActiveTripStore.instance.end();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/home'),
                      builder: (_) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Book another ride'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool on;
  const _Pill({required this.text, this.on = false});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: on ? p.safe : null,
        border: Border.all(color: on ? p.safe : p.line),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: on ? p.safeInk : p.inkDim)),
    );
  }
}
