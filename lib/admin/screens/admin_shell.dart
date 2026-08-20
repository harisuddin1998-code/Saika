import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/blurred_brand.dart';
import 'panels/overview_panel.dart';
import 'panels/registrations_panel.dart';
import 'panels/sos_queue_panel.dart';
import 'panels/verification_panel.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _panels = [
    OverviewPanel(),
    RegistrationsPanel(),
    SosQueuePanel(),
    VerificationPanel(),
  ];
  static const _destinations = [
    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Overview')),
    NavigationRailDestination(icon: Icon(Icons.how_to_reg_outlined), selectedIcon: Icon(Icons.how_to_reg), label: Text('Registrations')),
    NavigationRailDestination(icon: Icon(Icons.sos_outlined), selectedIcon: Icon(Icons.sos), label: Text('SOS Queue')),
    NavigationRailDestination(icon: Icon(Icons.verified_user_outlined), selectedIcon: Icon(Icons.verified_user), label: Text('Verification')),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: p.surface,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: BlurredBrand(
                child: Column(
                  children: [
                    Text('WO', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 20, color: p.accent)),
                    Text('SAFAR', style: TextStyle(fontFamily: 'monospace', fontSize: 9, letterSpacing: 2, color: p.muted)),
                  ],
                ),
              ),
            ),
            destinations: _destinations,
          ),
          VerticalDivider(width: 1, color: p.line),
          Expanded(child: IndexedStack(index: _index, children: _panels)),
        ],
      ),
    );
  }
}
