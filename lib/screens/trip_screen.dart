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
import 'bidding_screen.dart';
import 'home_screen.dart';
import 'rate_screen.dart';
import 'sos_screen.dart';
import 'trusted_circle_screen.dart';

const _freeCancelWindow = Duration(seconds: 20);

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
  LatLng? _driverLocation;
  late final DateTime _tripStartedAt;
  // Tracks whether we've ever confirmed via a state_snapshot that the
  // server still considers this trip active — a cancellation broadcast is
  // fire-and-forget, so if either side's connection drops for even a
  // moment around when the other cancels, that broadcast is gone for good.
  // Once we've seen the trip listed as active at least once, its absence
  // from a later snapshot means it was cancelled while we were briefly
  // disconnected, not that it never existed yet.
  bool _sawTripActive = false;
  Timer? _snapshotPoll;

  @override
  void initState() {
    super.initState();
    _tripStartedAt = DateTime.now();
    ActiveTripStore.instance.start(widget.driver, widget.request);
    pickup = LatLng(widget.request.pickupLat, widget.request.pickupLng);
    drop = LatLng(widget.request.dropLat, widget.request.dropLng);
    _routeFuture = fetchRoadRoute(pickup, drop);
    // Belt-and-suspenders on top of the live 'ride_cancelled' broadcast and
    // the reconnect-triggered snapshot: polls over plain REST every few
    // seconds so a cancellation is caught within a bounded time even if a
    // broadcast is silently dropped while both sides otherwise look
    // connected.
    _snapshotPoll = Timer.periodic(
      const Duration(seconds: 5),
      (_) => RealtimeService.instance.refreshSnapshot(),
    );
    _sub = RealtimeService.instance.events.listen((event) {
      if (event.type == 'state_snapshot') {
        final activeTripIds =
            (event.payload['activeTripIds'] as List?) ?? const [];
        final stillActive = activeTripIds.contains(widget.request.id);
        if (stillActive) {
          _sawTripActive = true;
        } else if (_sawTripActive && mounted) {
          _handleDriverCancelled();
        }
        return;
      }
      if (event.payload['requestId'] != widget.request.id) return;
      if (event.type == 'driver_location') {
        if (!mounted) return;
        final lat = (event.payload['lat'] as num?)?.toDouble();
        final lng = (event.payload['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return;
        setState(() => _driverLocation = LatLng(lat, lng));
        return;
      }
      if (event.type == 'ride_cancelled') {
        if (event.payload['cancelledBy'] != 'driver' || !mounted) return;
        _handleDriverCancelled();
        return;
      }
      if (event.type != 'driver_arrived') return;
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

  bool _handledCancellation = false;

  Future<void> _handleDriverCancelled() async {
    if (_handledCancellation) return;
    _handledCancellation = true;
    ActiveTripStore.instance.end();
    NotificationService.instance.show(
      'Ride cancelled',
      '${widget.driver.name} cancelled this ride.',
    );
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
        title: const Text('Ride cancelled'),
        content: Text(
          '${widget.driver.name} has cancelled this ride. We\'ll look for another driver for you now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    // The rider didn't choose to stop looking for a ride — the driver did —
    // so pick up the search automatically instead of dropping them back to
    // an empty home screen. Home stays underneath so "cancel" from the new
    // search still has somewhere to land.
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
    navigator.push(
      MaterialPageRoute(builder: (_) => BiddingScreen(request: widget.request)),
    );
  }

  Future<void> _cancelRide() async {
    final isLate = DateTime.now().difference(_tripStartedAt) > _freeCancelWindow;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: Text(
          isLate
              ? 'It\'s been more than 20 seconds since you accepted this driver — cancelling now may include a cancellation fee.'
              : 'You can cancel free of charge within 20 seconds of accepting a driver.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep ride'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isLate ? 'Cancel anyway' : 'Cancel ride'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final scaffold = ScaffoldMessenger.of(context);
    final sent = await RealtimeService.instance.sendReliably('ride_cancelled', {
      'requestId': widget.request.id,
      'cancelledBy': 'rider',
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
    ActiveTripStore.instance.end();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  /// A simple straight-line estimate (no live routing API for this) — good
  /// enough to give the rider a sense of "close" vs "still a while away".
  ({double km, int etaMin}) _distanceAndEta() {
    final target = _driverArrived ? drop : pickup;
    final km = const Distance().as(
      LengthUnit.Kilometer,
      _driverLocation!,
      target,
    );
    const avgCitySpeedKmh = 25.0;
    final etaMin = (km / avgCitySpeedKmh * 60).ceil().clamp(1, 999);
    return (km: km, etaMin: etaMin);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _snapshotPoll?.cancel();
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
                                : _driverLocation == null
                                ? '${driver.carModel} · ${driver.plate} · Locating driver…'
                                : '${driver.carModel} · ${driver.plate} · '
                                      '${_distanceAndEta().km.toStringAsFixed(1)} km away · '
                                      'ETA ~${_distanceAndEta().etaMin} min',
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
              if (_driverLocation != null)
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
                        'Tracking ${driver.name} live',
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
                    height: 150,
                    center: _driverLocation ?? pickup,
                    zoom: 13,
                    followCenter: true,
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
                        icon: Icons.flag,
                      ),
                      if (_driverLocation != null)
                        LiveMapPin(
                          point: _driverLocation!,
                          color: const Color(0xFFD6336C),
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
              const SizedBox(height: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: p.sos),
                onPressed: _cancelRide,
                child: const Text('Cancel ride'),
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
