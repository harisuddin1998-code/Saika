import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const _transactions = [
    ('Ride · Ayesha K.', 'Today, 11:02 AM', -400, true),
    ('Wallet top-up · JazzCash', 'Yesterday, 6:40 PM', 1000, false),
    ('Ride · Rabia B.', 'Yesterday, 9:15 AM', -380, true),
    ('Ride · Sana M.', '3 days ago', -420, true),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.accent, p.accent.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AVAILABLE BALANCE', style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, letterSpacing: 1.2, color: p.accentInk.withValues(alpha: 0.75))),
                const SizedBox(height: 8),
                Text('Rs 1,650', style: TextStyle(fontFamily: 'serif', fontSize: 36, fontWeight: FontWeight.bold, color: p.accentInk)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42), side: BorderSide(color: p.accentInk.withValues(alpha: 0.4)), foregroundColor: p.accentInk),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add money — coming soon'))),
                        child: const Text('+ Add money'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('PAYMENT METHODS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          _PaymentMethodRow(icon: Icons.account_balance_wallet, label: 'Saika Wallet', sub: 'Rs 1,650 available', selected: true),
          const SizedBox(height: 8),
          const _PaymentMethodRow(icon: Icons.smartphone, label: 'JazzCash', sub: 'Linked · 03•• ••• 214'),
          const SizedBox(height: 8),
          const _PaymentMethodRow(icon: Icons.smartphone, label: 'EasyPaisa', sub: 'Not linked'),
          const SizedBox(height: 8),
          const _PaymentMethodRow(icon: Icons.payments_outlined, label: 'Cash', sub: 'Pay driver directly'),
          const SizedBox(height: 26),
          Text('RECENT ACTIVITY', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          ..._transactions.map((t) => _TransactionRow(title: t.$1, subtitle: t.$2, amount: t.$3, isRide: t.$4)),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool selected;
  const _PaymentMethodRow({required this.icon, required this.label, required this.sub, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? p.accent : p.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: selected ? p.accent : p.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: p.ink, fontSize: 13.5)),
                Text(sub, style: TextStyle(fontSize: 11.5, color: p.muted)),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle, size: 18, color: p.accent),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final int amount;
  final bool isRide;
  const _TransactionRow({required this.title, required this.subtitle, required this.amount, required this.isRide});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final negative = amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(isRide ? Icons.directions_car : Icons.arrow_downward, size: 16, color: p.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: p.ink, fontSize: 13.5)),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: p.muted)),
              ],
            ),
          ),
          Text(
            '${negative ? '-' : '+'}Rs ${amount.abs()}',
            style: TextStyle(fontWeight: FontWeight.bold, color: negative ? p.ink : p.safe),
          ),
        ],
      ),
    );
  }
}
