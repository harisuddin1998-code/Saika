import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Contact us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ContactTile(icon: Icons.call, label: 'Call support', sub: '24/7 women-staffed helpline', palette: p),
          const SizedBox(height: 10),
          _ContactTile(icon: Icons.chat_bubble_outline, label: 'WhatsApp us', sub: 'Usually replies in minutes', palette: p),
          const SizedBox(height: 10),
          _ContactTile(icon: Icons.email_outlined, label: 'Email support', sub: 'support@ (name pending)', palette: p),
          const SizedBox(height: 10),
          _ContactTile(icon: Icons.help_outline, label: 'Help centre', sub: 'FAQs and safety guides', palette: p),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final AppPalette palette;
  const _ContactTile({required this.icon, required this.label, required this.sub, required this.palette});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label — demo only'))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.line)),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: palette.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: palette.ink, fontSize: 14)),
                  Text(sub, style: TextStyle(fontSize: 11.5, color: palette.muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.muted),
          ],
        ),
      ),
    );
  }
}
