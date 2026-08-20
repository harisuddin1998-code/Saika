import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/saika_pattern.dart';
import '../widgets/blurred_brand.dart';
import 'bookings_screen.dart';
import 'contact_screen.dart';
import 'login_screen.dart';
import 'trusted_circle_screen.dart';
import 'wallet_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Drawer(
      backgroundColor: p.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(color: p.accent),
              child: Column(
                children: [
                  CircleAvatar(radius: 32, backgroundColor: p.accentInk.withValues(alpha: 0.15), child: Icon(Icons.person, size: 32, color: p.accentInk)),
                  const SizedBox(height: 12),
                  Text('Hina N.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: p.accentInk)),
                  const SizedBox(height: 2),
                  Text('★ 4.9 rider rating', style: TextStyle(fontSize: 11.5, color: p.accentInk.withValues(alpha: 0.75))),
                ],
              ),
            ),
            const SaikaBand(height: 16),
            const SizedBox(height: 6),
            _DrawerTile(icon: Icons.home_outlined, label: 'Home', onTap: () => Navigator.of(context).pop()),
            _DrawerTile(
              icon: Icons.receipt_long_outlined,
              label: 'Bookings',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookingsScreen()));
              },
            ),
            _DrawerTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
              },
            ),
            _DrawerTile(
              icon: Icons.groups_outlined,
              label: 'Trusted Circle',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrustedCircleScreen()));
              },
            ),
            _DrawerTile(
              icon: Icons.support_agent_outlined,
              label: 'Contact us',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactScreen()));
              },
            ),
            const Spacer(),
            Divider(color: p.line, height: 1),
            _DrawerTile(
              icon: Icons.logout,
              label: 'Log out',
              danger: true,
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: BlurredBrand(child: Text('Saika'))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _DrawerTile({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return ListTile(
      leading: Icon(icon, color: danger ? p.sos : p.ink, size: 21),
      title: Text(label, style: TextStyle(color: danger ? p.sos : p.ink, fontWeight: FontWeight.w600, fontSize: 14.5)),
      onTap: onTap,
    );
  }
}
