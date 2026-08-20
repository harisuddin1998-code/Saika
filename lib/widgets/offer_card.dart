import 'package:flutter/material.dart';
import '../models/driver_offer.dart';
import '../theme/app_theme.dart';

class OfferCard extends StatelessWidget {
  final DriverOffer offer;
  final VoidCallback onAccept;

  const OfferCard({super.key, required this.offer, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: p.surface2,
            child: Text(offer.initials, style: TextStyle(color: p.ink, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(offer.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, color: p.ink, fontSize: 14)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: p.safe, borderRadius: BorderRadius.circular(100)),
                      child: Text('VERIFIED',
                          style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: p.safeInk)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${offer.carModel} · ${offer.carColor} · ★${offer.rating}',
                    style: TextStyle(fontSize: 11.5, color: p.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs ${offer.price}',
                  style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 16, color: p.ink)),
              const SizedBox(height: 6),
              SizedBox(
                height: 32,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: onAccept,
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
