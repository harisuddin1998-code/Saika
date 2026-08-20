import 'package:flutter/material.dart';
import '../models/trusted_contact.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_row.dart';

class TrustedCircleScreen extends StatefulWidget {
  const TrustedCircleScreen({super.key});

  @override
  State<TrustedCircleScreen> createState() => _TrustedCircleScreenState();
}

class _TrustedCircleScreenState extends State<TrustedCircleScreen> {
  final List<TrustedContact> _contacts = [
    TrustedContact(initial: 'A', name: 'Ammi', relation: 'Mother'),
    TrustedContact(initial: 'S', name: 'Baji Sara', relation: 'Sister'),
    TrustedContact(initial: 'T', name: 'Chacha Tariq', relation: 'Uncle'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Trusted Circle')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mahram Circle', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Text('Auto-shared on every ride', style: TextStyle(fontSize: 12.5, color: p.muted)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _contacts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = _contacts[i];
                  return ContactRow(
                    contact: c,
                    onToggle: (v) => setState(() => c.autoShare = v),
                  );
                },
              ),
            ),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add contact — coming soon')),
              ),
              child: const Text('+ Add contact'),
            ),
          ],
        ),
      ),
    );
  }
}
