import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/active_trip.dart';
import '../models/driver_offer.dart';
import '../models/ride_request.dart';
import '../services/notification_service.dart';
import '../services/realtime_service.dart';
import '../services/route_service.dart';
import '../theme/app_theme.dart';
import '../widgets/live_map.dart';
import '../widgets/sos_hold_button.dart';
import 'rate_screen.dart';
import 'sos_screen.dart';
import 'trusted_circle_screen.dart';

class TripScreen extends StatefulWidget {
  final DriverOffer driver;
  final RideRequest request;
  const TripScreen({super.key, required this.driver, required this.request});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  late final LatLng pickup;
  late final LatLng drop;
  late final Future<List<LatLng>> _routeFuture;
  StreamSubscription? _sub;
  bool _driverArrived = false;

  @override
  void initState() {
    super.initState();
    ActiveTripStore.instance.start(widget.driver, widget.request);
    pickup = LatLng(widget.request.pickupLat, widget.request.pickupLng);
    drop = LatLng(widget.request.dropLat, widget.request.dropLng);
    _routeFuture = fetchRoadRoute(pickup, drop);
    _sub = RealtimeService.instance.events.listen((event) {
      if (event.type != 'driver_arrived') return;
      if (event.payload['requestId'] != widget.request.id) return;
      if (_driverArrived || !mounted) return;
      setState(() => _driverArrived = true);
      ActiveTripStore.instance.markArrived();
      NotificationService.instance.show(
        'Your driver has arrived',
        '${widget.driver.name} is waiting at ${widget.request.pickup}.',
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Your driver has arrived'),
          content: Text(
            '${widget.driver.name} is waiting for you at ${widget.request.pickup}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
    final driver = widget.driver;
    final request = widget.request;
    return Scaffold(
      appBar: AppBar(title: const Text('On the way')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: p.surface2,
                      child: Text(
                        driver.initials,
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                driver.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: p.safe,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    color: p.safeInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _driverArrived
                                ? '${driver.carModel} · ${driver.plate} · Arrived'
                                : '${driver.carModel} · ${driver.plate} · ETA 4 min',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _driverArrived ? p.safeInk : p.muted,
                              fontWeight: _driverArrived
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_driverArrived) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: p.safe.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.safe),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pin_drop, size: 18, color: p.safeInk),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${driver.name} has arrived at your pickup location',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: p.safeInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FutureBuilder<List<LatLng>>(
                future: _routeFuture,
                builder: (context, snapshot) {
                  return LiveMapView(
                    height: 150,
                    center: pickup,
                    zoom: 13,
                    routePoints: snapshot.data ?? [pickup, drop],
                    pins: [
                      LiveMapPin(
                        point: pickup,
                        color: const Color(0xFFD6A24C),
                        icon: Icons.my_location,
                      ),
                      LiveMapPin(
                        point: drop,
                        color: const Color(0xFF4FAE7A),
                        icon: Icons.directions_car,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12, color: p.muted),
                  children: [
                    const TextSpan(text: 'Live location auto-shared with '),
                    TextSpan(
                      text: 'Ammi, Baji Sara',
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TrustedCircleScreen(),
                  ),
                ),
                child: const Text('View Trusted Circle'),
              ),
              const Spacer(),
              SosHoldButton(
                onTriggered: () {
                  final sosId = newEventId();
                  RealtimeService.instance.send('sos_triggered', {
                    'id': sosId,
                    'riderName': request.riderName,
                    'driverName': driver.name,
                    'area': request.pickup,
                    'triggeredAgo': 'just now',
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SosScreen(sosId: sosId)),
                  );
                },
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  ActiveTripStore.instance.end();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RateScreen(farePaid: driver.price),
                    ),
                  );
                },
                child: const Text('End trip (demo)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
