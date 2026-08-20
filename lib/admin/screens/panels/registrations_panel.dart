import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/realtime_service.dart';
import '../../../theme/app_theme.dart';

class Registration {
  final String name;
  final String phone;
  final String role;
  final String registeredAt;
  const Registration({
    required this.name,
    required this.phone,
    required this.role,
    required this.registeredAt,
  });

  factory Registration.fromJson(Map<String, dynamic> json) => Registration(
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    role: json['role'] as String? ?? 'rider',
    registeredAt: json['registeredAt'] as String? ?? '',
  );
}

class RegistrationsPanel extends StatefulWidget {
  const RegistrationsPanel({super.key});

  @override
  State<RegistrationsPanel> createState() => _RegistrationsPanelState();
}

class _RegistrationsPanelState extends State<RegistrationsPanel> {
  StreamSubscription? _sub;
  final List<Registration> _registrations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _sub = RealtimeService.instance.events.listen((event) {
      if (event.type != 'user_registered') return;
      setState(() => _registrations.insert(0, Registration.fromJson(event.payload)));
    });
  }

  Future<void> _loadInitial() async {
    try {
      final res = await http
          .get(Uri.parse('${RealtimeService.relayHttpBase}/registrations'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .map((e) => Registration.fromJson((e as Map).cast<String, dynamic>()))
            .toList()
            .reversed
            .toList();
        if (mounted) setState(() => _registrations.addAll(list));
      }
    } catch (_) {
      // Best-effort — live updates via the socket still work even if this fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final riders = _registrations.where((r) => r.role == 'rider').length;
    final drivers = _registrations.where((r) => r.role == 'driver').length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registrations', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Everyone who has registered from the landing page or an app', style: TextStyle(fontSize: 12.5, color: p.muted)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _StatTile(label: 'Total registered', value: '${_registrations.length}', accent: p.accent),
              _StatTile(label: 'Riders', value: '$riders', accent: p.accent),
              _StatTile(label: 'Drivers', value: '$drivers', accent: p.safe),
            ],
          ),
          const SizedBox(height: 24),
          Text('ALL REGISTRATIONS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _registrations.isEmpty
                    ? Center(
                        child: Text(
                          'No registrations yet.',
                          style: TextStyle(color: p.muted, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _registrations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final r = _registrations[i];
                          final isDriver = r.role == 'driver';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: p.line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDriver ? p.safe.withValues(alpha: 0.15) : p.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    r.role.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDriver ? p.safe : p.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.name.isEmpty ? '—' : r.name, style: TextStyle(fontWeight: FontWeight.bold, color: p.ink)),
                                      Text(r.phone, style: TextStyle(fontSize: 11.5, color: p.muted)),
                                    ],
                                  ),
                                ),
                                Text(_shortTime(r.registeredAt), style: TextStyle(fontSize: 11, color: p.muted)),
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

String _shortTime(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _StatTile({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, letterSpacing: 1, color: p.muted)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: 'serif', fontSize: 30, fontWeight: FontWeight.bold, color: accent)),
        ],
      ),
    );
  }
}
