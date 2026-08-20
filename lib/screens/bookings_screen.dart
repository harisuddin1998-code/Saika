import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  static const _trips = [
    ('Ayesha K.', 'Clifton → Tariq Road', 'Today, 11:02 AM', 400, 5.0),
    ('Rabia B.', 'Boat Basin → Saddar', 'Yesterday, 9:15 AM', 380, 4.9),
    ('Sana M.', 'DHA → Korangi', '3 days ago', 420, 5.0),
    ('Nimra K.', 'Gulshan → Clifton', 'Last week', 460, 4.8),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _trips.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = _trips[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
            child: Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: p.surface2, child: Text(t.$1[0], style: TextStyle(color: p.ink, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$1, style: TextStyle(fontWeight: FontWeight.bold, color: p.ink, fontSize: 14)),
                      Text(t.$2, style: TextStyle(fontSize: 11.5, color: p.muted)),
                      Text(t.$3, style: TextStyle(fontSize: 11, color: p.muted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rs ${t.$4}', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 15, color: p.ink)),
                    const SizedBox(height: 4),
                    Row(children: [Icon(Icons.star, size: 13, color: p.accent), Text(' ${t.$5}', style: TextStyle(fontSize: 11.5, color: p.muted))]),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
