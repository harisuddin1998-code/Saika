import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/ride_request.dart';
import '../../screens/sos_screen.dart';
import '../../services/realtime_service.dart';
import '../../services/route_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/live_map.dart';
import '../../widgets/sos_hold_button.dart';
import '../models/driver_identity.dart';
import 'driver_home_screen.dart';

class DriverTripScreen extends StatefulWidget {
  final RideRequest request;
  final int agreedPrice;
  const DriverTripScreen({
    super.key,
    required this.request,
    required this.agreedPrice,
  });

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  late final LatLng pickup;
  late final LatLng drop;
  late final Future<List<LatLng>> _routeFuture;
  bool _arrivedAtPickup = false;

  @override
  void initState() {
    super.initState();
    pickup = LatLng(widget.request.pickupLat, widget.request.pickupLng);
    drop = LatLng(widget.request.dropLat, widget.request.dropLng);
    _routeFuture = fetchRoadRoute(pickup, drop);
  }

  Future<void> _markArrived() async {
    final scaffold = ScaffoldMessenger.of(context);
    final sent = await RealtimeService.instance.sendReliably('driver_arrived', {
      'requestId': widget.request.id,
      'driverName': DriverIdentity.name,
    });
    if (!mounted) return;
    if (!sent) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text(
            'No connection — couldn\'t notify the rider. Check your internet and try again.',
          ),
        ),
      );
      return;
    }
    setState(() => _arrivedAtPickup = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final request = widget.request;
    final agreedPrice = widget.agreedPrice;
    return Scaffold(
      appBar: AppBar(
        title: Text(_arrivedAtPickup ? 'Active trip' : 'Heading to pickup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: p.surface2,
                      child: Text(
                        request.riderInitials,
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.riderName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                          Text(
                            '${request.pickup} → ${request.dropoff}',
                            style: TextStyle(fontSize: 11.5, color: p.muted),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                request.rideType.icon,
                                size: 13,
                                color: p.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${request.rideType.label} trip',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: p.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs $agreedPrice',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: p.safe,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<LatLng>>(
                future: _routeFuture,
                builder: (context, snapshot) {
                  return LiveMapView(
                    height: 170,
                    center: pickup,
                    zoom: 13,
                    routePoints: snapshot.data ?? [pickup, drop],
                    pins: [
                      LiveMapPin(
                        point: pickup,
                        color: const Color(0xFF4FAE7A),
                        icon: Icons.directions_car,
                      ),
                      LiveMapPin(
                        point: drop,
                        color: const Color(0xFFD6A24C),
                        icon: Icons.flag,
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              SosHoldButton(
                onTriggered: () {
                  final sosId = newEventId();
                  RealtimeService.instance.send('sos_triggered', {
                    'id': sosId,
                    'riderName': request.riderName,
                    'driverName': DriverIdentity.name,
                    'area': request.pickup,
                    'triggeredAgo': 'just now',
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SosScreen(sosId: sosId)),
                  );
                },
              ),
              const SizedBox(height: 18),
              if (!_arrivedAtPickup)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _markArrived,
                  icon: const Icon(Icons.pin_drop_outlined, size: 18),
                  label: const Text("I've reached the pickup location"),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.safe,
                    foregroundColor: p.safeInk,
                  ),
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/driver_home'),
                      builder: (_) => const DriverHomeScreen(),
                    ),
                    (route) => false,
                  ),
                  child: const Text('Complete trip'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
