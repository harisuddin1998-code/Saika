import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/ride_request.dart';
import '../../../services/realtime_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/live_map.dart';

class OverviewPanel extends StatefulWidget {
  const OverviewPanel({super.key});

  @override
  State<OverviewPanel> createState() => _OverviewPanelState();
}

class _OverviewPanelState extends State<OverviewPanel> {
  StreamSubscription? _sub;
  final List<RideRequest> _activeRides = [];
  int _activeSosCount = 0;
  int _onlineCount = 0;
  Map<String, int> _byRole = const {};

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
        final active = (event.payload['activeRequests'] as List?) ?? const [];
        final sos = (event.payload['activeSos'] as List?) ?? const [];
        setState(() {
          _activeRides
            ..clear()
            ..addAll(
              active
                  .map((r) => RideRequest.fromJson((r as Map).cast<String, dynamic>()))
                  .where((r) => !r.isStale),
            );
          _activeSosCount = sos.length;
          _onlineCount = (event.payload['onlineCount'] as num?)?.toInt() ?? 0;
        });
        break;
      case 'ride_request':
        final r = RideRequest.fromJson(event.payload);
        if (r.isStale) return;
        if (_activeRides.any((x) => x.id == r.id)) return;
        setState(() => _activeRides.add(r));
        break;
      case 'ride_accepted':
      case 'ride_cancelled':
        setState(() => _activeRides.removeWhere((r) => r.id == event.payload['requestId']));
        break;
      case 'sos_triggered':
        setState(() => _activeSosCount++);
        break;
      case 'sos_resolved':
        setState(() => _activeSosCount = (_activeSosCount - 1).clamp(0, 999));
        break;
      case 'presence':
        setState(() {
          _onlineCount = (event.payload['onlineCount'] as num?)?.toInt() ?? 0;
          _byRole = (event.payload['byRole'] as Map?)?.cast<String, int>() ?? const {};
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final pins = <LiveMapPin>[
      for (final r in _activeRides) LiveMapPin(point: LatLng(r.pickupLat, r.pickupLng), color: p.accent, icon: Icons.directions_car),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Live overview', style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              _ConnectionBadge(onlineCount: _onlineCount, byRole: _byRole),
            ],
          ),
          const SizedBox(height: 4),
          Text('Pakistan-wide pilot · live from the realtime relay', style: TextStyle(fontSize: 12.5, color: p.muted)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _StatTile(label: 'Active ride requests', value: '${_activeRides.length}', accent: p.accent),
              _StatTile(label: 'Connected apps', value: '$_onlineCount', accent: p.safe),
              _StatTile(label: 'Open SOS alerts', value: '$_activeSosCount', accent: _activeSosCount > 0 ? p.sos : p.safe),
            ],
          ),
          const SizedBox(height: 24),
          Text('ACTIVE RIDES MAP', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          LiveMapView(
            height: 360,
            center: pins.isNotEmpty ? pins.first.point : KarachiPoints.clifton,
            zoom: 12.3,
            pins: pins,
          ),
          if (_activeRides.isEmpty) ...[
            const SizedBox(height: 12),
            Text('No active ride requests yet — send one from the rider app to see it appear here live.', style: TextStyle(fontSize: 12.5, color: p.muted)),
          ],
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final int onlineCount;
  final Map<String, int> byRole;
  const _ConnectionBadge({required this.onlineCount, required this.byRole});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final parts = byRole.entries.map((e) => '${e.value} ${e.key}').join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(100), border: Border.all(color: p.line)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: onlineCount > 0 ? p.safe : p.muted, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(parts.isEmpty ? 'No apps connected' : parts, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: p.muted)),
        ],
      ),
    );
  }
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
      width: 180,
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
