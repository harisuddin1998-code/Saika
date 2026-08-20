import 'package:flutter/material.dart';
import '../services/realtime_service.dart';
import '../theme/app_theme.dart';

class SosScreen extends StatelessWidget {
  final String sosId;
  const SosScreen({super.key, required this.sosId});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      backgroundColor: p.sos,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EMERGENCY', style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, letterSpacing: 1.5, color: p.sosInk.withValues(alpha: 0.75))),
              const SizedBox(height: 8),
              Text('SOS Sent', style: TextStyle(fontFamily: 'serif', fontSize: 30, fontWeight: FontWeight.bold, color: p.sosInk)),
              const SizedBox(height: 22),
              _StatusRow(text: 'Control Room notified', ink: p.sosInk),
              const SizedBox(height: 12),
              _StatusRow(text: 'Trusted Circle notified', ink: p.sosInk),
              const SizedBox(height: 12),
              _StatusRow(text: 'Live location streaming', ink: p.sosInk),
              const SizedBox(height: 12),
              _StatusRow(text: 'Emergency helpline dialed', ink: p.sosInk),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: p.sos),
                  onPressed: () {
                    RealtimeService.instance.send('sos_resolved', {'id': sosId});
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel — I'm safe"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white70), foregroundColor: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connecting to Control Room…')),
                    );
                  },
                  child: const Text('Stay on line with Control Room'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String text;
  final Color ink;
  const _StatusRow({required this.text, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(Icons.check, size: 12, color: ink),
        ),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 13.5, color: ink)),
      ],
    );
  }
}
