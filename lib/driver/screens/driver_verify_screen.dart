import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'driver_home_screen.dart';

class DriverVerifyScreen extends StatelessWidget {
  const DriverVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Verification status')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCard(title: 'CNIC verification', status: 'Approved', done: true, palette: p),
            const SizedBox(height: 12),
            _StatusCard(title: 'Police character certificate', status: 'Approved', done: true, palette: p),
            const SizedBox(height: 12),
            _StatusCard(title: 'EV registration & inspection', status: 'Approved', done: true, palette: p),
            const SizedBox(height: 12),
            _StatusCard(title: 'Selfie login match', status: 'Set up', done: true, palette: p),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
              child: Row(
                children: [
                  Icon(Icons.verified, color: p.safe, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text('All checks passed — you are cleared to drive on Saika.', style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: p.safe, foregroundColor: p.safeInk),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(settings: const RouteSettings(name: '/driver_home'), builder: (_) => const DriverHomeScreen()),
              ),
              child: const Text('Go to dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final bool done;
  final AppPalette palette;
  const _StatusCard({required this.title, required this.status, required this.done, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: palette.line)),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: done ? palette.safe : palette.surface2, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(done ? Icons.check : Icons.hourglass_empty, size: 13, color: done ? palette.safeInk : palette.muted),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: palette.ink, fontSize: 13.5))),
          Text(status, style: TextStyle(fontSize: 12, color: done ? palette.safe : palette.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
