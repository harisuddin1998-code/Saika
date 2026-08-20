import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/ride_request.dart';
import '../../services/realtime_service.dart';
import '../../theme/app_theme.dart';
import '../models/driver_identity.dart';
import 'driver_trip_screen.dart';

/// Shown after a driver sends an offer — several drivers can offer on the
/// same request, so this waits for the rider to pick one. Only moves on to
/// the trip screen if THIS driver is the one the rider chose; otherwise
/// shows that the offer wasn't selected so the driver never ends up
/// thinking they have a trip that another driver was actually given.
class DriverAwaitingResponseScreen extends StatefulWidget {
  final RideRequest request;
  final int counteredPrice;
  const DriverAwaitingResponseScreen({
    super.key,
    required this.request,
    required this.counteredPrice,
  });

  @override
  State<DriverAwaitingResponseScreen> createState() =>
      _DriverAwaitingResponseScreenState();
}

class _DriverAwaitingResponseScreenState
    extends State<DriverAwaitingResponseScreen> {
  StreamSubscription? _sub;
  // null = still waiting; 'not_selected' = rider chose another driver;
  // 'cancelled' = rider cancelled the ride request entirely.
  String? _endedReason;

  @override
  void initState() {
    super.initState();
    _sub = RealtimeService.instance.events.listen((event) {
      if (event.payload['requestId'] != widget.request.id) return;
      if (!mounted) return;
      if (event.type == 'ride_cancelled') {
        setState(() => _endedReason = 'cancelled');
        return;
      }
      if (event.type == 'ride_offer_declined') {
        if (event.payload['driverId'] != DriverIdentity.deviceId) return;
        setState(() => _endedReason = 'declined');
        return;
      }
      if (event.type != 'ride_accepted') return;
      final isMe = event.payload['driverId'] == DriverIdentity.deviceId;
      if (isMe) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DriverTripScreen(
              request: widget.request,
              agreedPrice: widget.counteredPrice,
            ),
          ),
        );
      } else {
        setState(() => _endedReason = 'not_selected');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final r = widget.request;
    final ended = _endedReason != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_endedReason) {
          'not_selected' => 'Offer not selected',
          'declined' => 'Offer declined',
          'cancelled' => 'Ride cancelled',
          _ => 'Waiting for rider',
        }),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              switch (_endedReason) {
                'not_selected' => '${r.riderName} went with another driver',
                'declined' => '${r.riderName} declined your offer',
                'cancelled' => '${r.riderName} cancelled this ride',
                _ => 'Your offer sent to ${r.riderName}',
              },
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              '${r.pickup} → ${r.dropoff}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Center(
                child: ended
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 40, color: p.muted),
                          const SizedBox(height: 14),
                          Text(
                            'No worries — go back online to see new requests.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.muted, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context).popUntil((r) => r.isFirst),
                            child: const Text('Back to dashboard'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              color: p.safe,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Rs ${widget.counteredPrice}',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: p.safe,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Waiting for ${r.riderName} to choose a driver…',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.muted, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
