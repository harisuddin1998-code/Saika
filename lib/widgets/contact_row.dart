import 'package:flutter/material.dart';
import '../models/trusted_contact.dart';
import '../theme/app_theme.dart';

class ContactRow extends StatelessWidget {
  final TrustedContact contact;
  final ValueChanged<bool> onToggle;

  const ContactRow({super.key, required this.contact, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 19, backgroundColor: p.accent, child: Text(contact.initial, style: TextStyle(color: p.accentInk, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: p.ink)),
                Text(contact.relation, style: TextStyle(fontSize: 11.5, color: p.muted)),
              ],
            ),
          ),
          Switch(value: contact.autoShare, onChanged: onToggle),
        ],
      ),
    );
  }
}
