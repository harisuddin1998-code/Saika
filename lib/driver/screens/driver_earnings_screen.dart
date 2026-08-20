import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  static const _trips = [
    ('Hina N.', 'Clifton → Tariq Road', 'Today, 11:04 AM', 400, 360, 40),
    ('Zoya F.', 'Boat Basin → Saddar', 'Today, 9:20 AM', 320, 288, 32),
    ('Mahnoor A.', 'DHA → Korangi', 'Yesterday, 6:10 PM', 480, 432, 48),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final grossToday = _trips.fold<int>(0, (sum, t) => sum + t.$4);
    final netToday = _trips.fold<int>(0, (sum, t) => sum + t.$5);
    final commission = grossToday - netToday;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & earnings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.safe, p.safe.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AVAILABLE FOR PAYOUT', style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, letterSpacing: 1.2, color: p.safeInk.withValues(alpha: 0.75))),
                const SizedBox(height: 8),
                Text('Rs $netToday', style: TextStyle(fontFamily: 'serif', fontSize: 36, fontWeight: FontWeight.bold, color: p.safeInk)),
                const SizedBox(height: 4),
                Text('${_trips.length} trips today', style: TextStyle(fontSize: 12, color: p.safeInk.withValues(alpha: 0.8))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42), side: BorderSide(color: p.safeInk.withValues(alpha: 0.4)), foregroundColor: p.safeInk),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Instant payout requested — funds arrive in minutes')),
                    ),
                    child: const Text('Cash out now'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _Breakdown(label: 'Gross fares', value: 'Rs $grossToday', color: p.ink, palette: p)),
              const SizedBox(width: 10),
              Expanded(child: _Breakdown(label: 'Platform fee', value: '-Rs $commission', color: p.muted, palette: p)),
              const SizedBox(width: 10),
              Expanded(child: _Breakdown(label: 'Your earnings', value: 'Rs $netToday', color: p.safe, palette: p)),
            ],
          ),
          const SizedBox(height: 24),
          Text('THIS WEEK', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _WeekStat(day: 'Mon', amount: 980),
                _WeekStat(day: 'Tue', amount: 1120),
                _WeekStat(day: 'Wed', amount: 860),
                _WeekStat(day: 'Thu', amount: 1240),
                _WeekStat(day: 'Fri', amount: 1080),
                _WeekStat(day: 'Sat', amount: 1360),
                _WeekStat(day: 'Today', amount: 360, highlight: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('TRIP HISTORY', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          ..._trips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.$1, style: TextStyle(fontWeight: FontWeight.w600, color: p.ink, fontSize: 13.5)),
                            Text('${t.$2} · ${t.$3}', style: TextStyle(fontSize: 11, color: p.muted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Rs ${t.$5}', style: TextStyle(fontWeight: FontWeight.bold, color: p.ink)),
                          Text('fare Rs ${t.$4}', style: TextStyle(fontSize: 10.5, color: p.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AppPalette palette;
  const _Breakdown({required this.label, required this.value, required this.color, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: palette.line)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: palette.muted), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String day;
  final int amount;
  final bool highlight;
  const _WeekStat({required this.day, required this.amount, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final barHeight = (amount / 1360 * 64).clamp(8, 64).toDouble();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 10,
          height: barHeight,
          decoration: BoxDecoration(color: highlight ? p.accent : p.safe.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 6),
        Text(day, style: TextStyle(fontSize: 9.5, color: p.muted)),
      ],
    );
  }
}
