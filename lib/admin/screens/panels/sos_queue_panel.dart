import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/realtime_service.dart';
import '../../../theme/app_theme.dart';
import '../../models/sos_alert.dart';

class SosQueuePanel extends StatefulWidget {
  const SosQueuePanel({super.key});

  @override
  State<SosQueuePanel> createState() => _SosQueuePanelState();
}

class _SosQueuePanelState extends State<SosQueuePanel> {
  StreamSubscription? _sub;
  final List<SosAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _sub = RealtimeService.instance.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(RealtimeEvent event) {
    switch (event.type) {
      case 'state_snapshot':
        final active = (event.payload['activeSos'] as List?) ?? const [];
        setState(() {
          _alerts
            ..clear()
            ..addAll(active.map((s) => _fromJson((s as Map).cast<String, dynamic>())));
        });
        break;
      case 'sos_triggered':
        setState(() => _alerts.insert(0, _fromJson(event.payload)));
        break;
      case 'sos_resolved':
        final id = event.payload['id'];
        final i = _alerts.indexWhere((a) => a.id == id);
        if (i == -1) return;
        setState(() => _alerts[i] = _alerts[i].copyWith(status: SosStatus.resolved));
        break;
    }
  }

  SosAlert _fromJson(Map<String, dynamic> json) => SosAlert(
        id: json['id'] as String? ?? '',
        riderName: json['riderName'] as String? ?? 'Rider',
        driverName: json['driverName'] as String? ?? 'Driver',
        area: json['area'] as String? ?? '',
        triggeredAgo: json['triggeredAgo'] as String? ?? 'just now',
        status: SosStatus.active,
      );

  void _resolve(String id) {
    RealtimeService.instance.send('sos_resolved', {'id': id});
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SOS alert queue', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Active alerts need a response within 60 seconds', style: TextStyle(fontSize: 12.5, color: p.muted)),
          const SizedBox(height: 20),
          Expanded(
            child: _alerts.isEmpty
                ? Center(child: Text('No SOS alerts yet — trigger one from the rider or driver app to see it here live.', style: TextStyle(color: p.muted, fontSize: 13)))
                : ListView.separated(
                    itemCount: _alerts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = _alerts[i];
                      final active = a.status == SosStatus.active;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: active ? p.sos : p.line, width: active ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: active ? p.sos : p.surface2, borderRadius: BorderRadius.circular(100)),
                              child: Text(
                                active ? 'ACTIVE' : 'RESOLVED',
                                style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.bold, color: active ? p.sosInk : p.muted),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${a.riderName} · driver ${a.driverName}', style: TextStyle(fontWeight: FontWeight.bold, color: p.ink)),
                                  Text('${a.area} · triggered ${a.triggeredAgo}', style: TextStyle(fontSize: 12, color: p.muted)),
                                ],
                              ),
                            ),
                            if (active)
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(140, 40),
                                  backgroundColor: p.sos,
                                  foregroundColor: p.sosInk,
                                ),
                                onPressed: () => _resolve(a.id),
                                child: const Text('Mark resolved'),
                              )
                            else
                              Icon(Icons.check_circle, color: p.safe),
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
