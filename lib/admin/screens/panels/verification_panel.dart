import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../models/driver_application.dart';

class VerificationPanel extends StatefulWidget {
  const VerificationPanel({super.key});

  @override
  State<VerificationPanel> createState() => _VerificationPanelState();
}

class _VerificationPanelState extends State<VerificationPanel> {
  final List<DriverApplication> _applications = [
    const DriverApplication(name: 'Nimra K.', vehicle: 'Suzuki EV · White', submittedAgo: '1 day ago', cnicVerified: true, policeCertVerified: true),
    const DriverApplication(name: 'Areeba H.', vehicle: 'BYD EV · Grey', submittedAgo: '2 days ago', cnicVerified: true, policeCertVerified: false),
  ];

  void _decide(int i, bool approve) => setState(() => _applications.removeAt(i));

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Driver verification queue', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('${_applications.length} pending applications', style: TextStyle(fontSize: 12.5, color: p.muted)),
          const SizedBox(height: 20),
          Expanded(
            child: _applications.isEmpty
                ? Center(child: Text('Queue is clear', style: TextStyle(color: p.muted)))
                : ListView.separated(
                    itemCount: _applications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = _applications[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.name, style: TextStyle(fontWeight: FontWeight.bold, color: p.ink, fontSize: 15)),
                                  Text('${a.vehicle} · submitted ${a.submittedAgo}', style: TextStyle(fontSize: 12, color: p.muted)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _CheckPill(label: 'CNIC', ok: a.cnicVerified, palette: p),
                                      _CheckPill(label: 'Police cert', ok: a.policeCertVerified, palette: p),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(96, 38)),
                                  onPressed: () => _decide(i, false),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(height: 8),
                                FilledButton(
                                  style: FilledButton.styleFrom(minimumSize: const Size(96, 38), backgroundColor: p.safe, foregroundColor: p.safeInk),
                                  onPressed: () => _decide(i, true),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CheckPill extends StatelessWidget {
  final String label;
  final bool ok;
  final AppPalette palette;
  const _CheckPill({required this.label, required this.ok, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? palette.safe.withValues(alpha: 0.15) : palette.sos.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: ok ? palette.safe : palette.sos),
      ),
      child: Text(
        '${ok ? '✓' : '!'} $label',
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: ok ? palette.safe : palette.sos),
      ),
    );
  }
}
