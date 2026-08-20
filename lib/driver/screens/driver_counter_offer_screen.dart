import 'package:flutter/material.dart';
import '../../models/ride_request.dart';
import '../../theme/app_theme.dart';

class DriverCounterOfferScreen extends StatefulWidget {
  final RideRequest request;
  const DriverCounterOfferScreen({super.key, required this.request});

  @override
  State<DriverCounterOfferScreen> createState() => _DriverCounterOfferScreenState();
}

class _DriverCounterOfferScreenState extends State<DriverCounterOfferScreen> {
  late int _price = widget.request.proposedPrice;

  void _adjust(int delta) => setState(() => _price = (_price + delta).clamp(50, 5000));

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final r = widget.request;
    return Scaffold(
      appBar: AppBar(title: const Text('Make an offer')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.riderName} proposed', style: Theme.of(context).textTheme.bodyMedium),
            Text('Rs ${r.proposedPrice}', style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: p.muted)),
            const SizedBox(height: 6),
            Text('${r.pickup} → ${r.dropoff} · ${r.distanceKm} km', style: TextStyle(fontSize: 12.5, color: p.muted)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.safe)),
              child: Column(
                children: [
                  Text('YOUR OFFER', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepButton(icon: Icons.remove, onTap: () => _adjust(-25)),
                      SizedBox(
                        width: 120,
                        child: Text('Rs $_price', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'serif', fontSize: 32, fontWeight: FontWeight.bold, color: p.safe)),
                      ),
                      _StepButton(icon: Icons.add, onTap: () => _adjust(25)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: p.safe, foregroundColor: p.safeInk),
              onPressed: () => Navigator.of(context).pop(_price),
              child: const Text('Send offer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: p.surface2, shape: BoxShape.circle, border: Border.all(color: p.line)),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: p.ink),
      ),
    );
  }
}
