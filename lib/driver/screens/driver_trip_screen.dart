import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ride_request.dart';
import '../../screens/sos_screen.dart';
import '../../services/realtime_service.dart';
import '../../services/route_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/live_map.dart';
import '../../widgets/sos_hold_button.dart';
import '../models/driver_identity.dart';
import 'driver_home_screen.dart';

const _freeCancelWindow = Duration(seconds: 20);

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
  late final DateTime _tripStartedAt;
  bool _arrivedAtPickup = false;
  Timer? _locationTimer;
  StreamSubscription? _sub;
  LatLng? _myLocation;
  // Same reconciliation as the rider's trip screen — a cancellation
  // broadcast is fire-and-forget, so a brief connection drop around when
  // the rider cancels can mean this broadcast never arrives. Once a
  // state_snapshot has confirmed the trip is active at least once, its
  // later absence means it was cancelled while we were briefly disconnected.
  bool _sawTripActive = false;
  bool _handledCancellation = false;

  @override
  void initState() {
    super.initState();
    _tripStartedAt = DateTime.now();
    pickup = LatLng(widget.request.pickupLat, widget.request.pickupLng);
    drop = LatLng(widget.request.dropLat, widget.request.dropLng);
    _routeFuture = fetchRoadRoute(pickup, drop);
    _startSharingLocation();
    _sub = RealtimeService.instance.events.listen((event) {
      if (event.type == 'state_snapshot') {
        final activeTripIds =
            (event.payload['activeTripIds'] as List?) ?? const [];
        final stillActive = activeTripIds.contains(widget.request.id);
        if (stillActive) {
          _sawTripActive = true;
        } else if (_sawTripActive && mounted) {
          _handleRiderCancelled();
        }
        return;
      }
      if (event.type != 'ride_cancelled') return;
      if (event.payload['requestId'] != widget.request.id) return;
      if (event.payload['cancelledBy'] != 'rider' || !mounted) return;
      _handleRiderCancelled();
    });
  }

  RideRequest get request => widget.request;

  Future<void> _handleRiderCancelled() async {
    if (_handledCancellation) return;
    _handledCancellation = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
        title: const Text('Ride cancelled'),
        content: Text('${request.riderName} has cancelled this ride.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/driver_home'),
        builder: (_) => const DriverHomeScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _startSharingLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _warnLocationUnavailable();
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      _warnLocationUnavailable();
      return;
    }

    Future<void> pushLocation() async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
        }
        RealtimeService.instance.send('driver_location', {
          'requestId': widget.request.id,
          'lat': pos.latitude,
          'lng': pos.longitude,
        });
      } catch (_) {
        // Best-effort — a missed update just means the rider's map is
        // briefly stale, not worth surfacing an error for.
      }
    }

    await pushLocation();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => pushLocation(),
    );
  }

  Future<void> _navigateToTarget() async {
    final target = _arrivedAtPickup ? drop : pickup;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${target.latitude},${target.longitude}'
      '&travelmode=driving',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t open Maps for navigation.')),
      );
    }
  }

  void _warnLocationUnavailable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location is off — turn it on so the rider can see you on the map.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    });
  }

  /// Straight-line estimate to the pickup (or the drop-off, once the trip is
  /// under way) — no live routing API for this, just enough to give a sense
  /// of "close" vs "still a while away".
  ({double km, int etaMin}) _distanceAndEta() {
    final target = _arrivedAtPickup ? drop : pickup;
    final km = const Distance().as(LengthUnit.Kilometer, _myLocation!, target);
    const avgCitySpeedKmh = 25.0;
    final etaMin = (km / avgCitySpeedKmh * 60).ceil().clamp(1, 999);
    return (km: km, etaMin: etaMin);
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _sub?.cancel();
    super.dispose();
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

  Future<void> _cancelTrip() async {
    final isLate = DateTime.now().difference(_tripStartedAt) > _freeCancelWindow;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this trip?'),
        content: Text(
          isLate
              ? 'It\'s been more than 20 seconds since you accepted — cancelling now may include a cancellation fee.'
              : 'You can cancel free of charge within 20 seconds of accepting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep trip'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isLate ? 'Cancel anyway' : 'Cancel trip'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final scaffold = ScaffoldMessenger.of(context);
    final sent = await RealtimeService.instance.sendReliably('ride_cancelled', {
      'requestId': widget.request.id,
      'cancelledBy': 'driver',
      'lateCancellation': isLate,
    });
    if (!mounted) return;
    if (!sent) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text(
            'No connection — couldn\'t cancel. Check your internet and try again.',
          ),
        ),
      );
      return;
    }
    _handledCancellation = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/driver_home'),
        builder: (_) => const DriverHomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
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
                            _myLocation == null
                                ? '${request.pickup} → ${request.dropoff}'
                                : '${_distanceAndEta().km.toStringAsFixed(1)} km away · '
                                      'ETA ~${_distanceAndEta().etaMin} min',
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
              if (_myLocation != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD6336C),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _arrivedAtPickup
                            ? 'Following route to drop-off'
                            : 'Following route to ${request.riderName}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              FutureBuilder<List<LatLng>>(
                future: _routeFuture,
                builder: (context, snapshot) {
                  return LiveMapView(
                    height: 170,
                    center: _myLocation ?? pickup,
                    zoom: 13,
                    followCenter: true,
                    routePoints: snapshot.data ?? [pickup, drop],
                    pins: [
                      LiveMapPin(
                        point: pickup,
                        color: const Color(0xFF4FAE7A),
                        icon: Icons.my_location,
                      ),
                      LiveMapPin(
                        point: drop,
                        color: const Color(0xFFD6A24C),
                        icon: Icons.flag,
                      ),
                      if (_myLocation != null)
                        LiveMapPin(
                          point: _myLocation!,
                          color: const Color(0xFFD6336C),
                          icon: Icons.directions_car,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: p.ink,
                  foregroundColor: Colors.white,
                ),
                onPressed: _navigateToTarget,
                icon: const Icon(Icons.navigation_outlined, size: 18),
                label: Text(
                  _arrivedAtPickup
                      ? 'Navigate to drop-off'
                      : 'Navigate to passenger',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: p.sos),
                onPressed: _cancelTrip,
                child: const Text('Cancel trip'),
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
