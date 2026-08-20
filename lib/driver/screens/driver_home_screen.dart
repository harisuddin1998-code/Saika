import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/ride_request.dart';
import '../../services/notification_service.dart';
import '../../services/realtime_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/saika_wallpaper.dart';
import '../models/driver_identity.dart';
import 'driver_awaiting_response_screen.dart';
import 'driver_counter_offer_screen.dart';
import 'driver_drawer.dart';
import 'driver_earnings_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _online = true;
  final List<RideRequest> _requests = [];
  final Set<String> _bumpedRequestIds = {};
  StreamSubscription? _sub;

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

  // Passenger service stays women-only regardless — this only decides
  // whether an age-verified male driver may see & offer on a request, based
  // on what the rider chose when booking.
  bool _visibleToThisDriver(RideRequest request) =>
      DriverIdentity.gender == 'female' ||
      request.preferredDriverGender == 'any';

  void _onEvent(RealtimeEvent event) {
    switch (event.type) {
      case 'state_snapshot':
        final active = (event.payload['activeRequests'] as List?) ?? const [];
        setState(() {
          _requests
            ..clear()
            ..addAll(
              active
                  .map(
                    (r) => RideRequest.fromJson(
                      (r as Map).cast<String, dynamic>(),
                    ),
                  )
                  // The relay never expires activeRequests on its own, so a
                  // long-running test session accumulates old abandoned
                  // requests forever — filter those out here rather than
                  // showing a driver a request that's actually long dead.
                  .where((r) => !r.isStale)
                  .where(_visibleToThisDriver),
            );
        });
        break;
      case 'ride_request':
        final request = RideRequest.fromJson(event.payload);
        if (request.isStale) return;
        if (!_visibleToThisDriver(request)) return;
        if (_requests.any((r) => r.id == request.id)) return;
        setState(() => _requests.add(request));
        if (_online) {
          NotificationService.instance.show(
            'New ride request',
            '${request.riderName} · Rs ${request.proposedPrice} · ${request.pickup} → ${request.dropoff}',
          );
        }
        break;
      case 'ride_accepted':
      case 'ride_cancelled':
        setState(
          () =>
              _requests.removeWhere((r) => r.id == event.payload['requestId']),
        );
        break;
      case 'ride_bid_updated':
        final updated = RideRequest.fromJson(event.payload);
        if (!_visibleToThisDriver(updated)) return;
        setState(() {
          final i = _requests.indexWhere((r) => r.id == updated.id);
          if (i == -1) {
            _requests.add(updated);
          } else {
            _requests[i] = updated;
          }
          _bumpedRequestIds.add(updated.id);
        });
        break;
    }
  }

  Future<void> _sendOffer(RideRequest request, int price) async {
    final scaffold = ScaffoldMessenger.of(context);
    final sent = await RealtimeService.instance.sendReliably('ride_countered', {
      'requestId': request.id,
      'driverId': DriverIdentity.deviceId,
      'driverInitials': DriverIdentity.initials,
      'driverName': DriverIdentity.name,
      'carModel': DriverIdentity.carModel,
      'carColor': DriverIdentity.carColor,
      'plate': DriverIdentity.plate,
      'rating': DriverIdentity.rating,
      'price': price,
    });
    if (!mounted) return;
    if (!sent) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text(
            'No connection — couldn\'t send your offer. Check your internet and try again.',
          ),
        ),
      );
      return;
    }
    setState(() => _requests.removeWhere((r) => r.id == request.id));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverAwaitingResponseScreen(
          request: request,
          counteredPrice: price,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      drawer: const DriverDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          const _ConnectionBadge(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DriverEarningsScreen()),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: SaikaWallpaper(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _online ? p.safe.withValues(alpha: 0.12) : p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _online ? p.safe : p.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _online ? p.safe : p.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _online ? 'Online — visible to riders' : 'Offline',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                    ),
                    Switch(
                      value: _online,
                      onChanged: (v) => setState(() => _online = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _online ? 'Nearby fare requests' : 'Go online to see requests',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 10),
              if (_online)
                Expanded(
                  child: _requests.isEmpty
                      ? Center(
                          child: Text(
                            'Waiting for a rider to request a ride…',
                            style: TextStyle(
                              color: p.muted,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _requests.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = _requests[i];
                            return _RequestCard(
                              request: r,
                              bidRaised: _bumpedRequestIds.contains(r.id),
                              onDismiss: () => setState(
                                () => _requests.removeWhere(
                                  (x) => x.id == r.id,
                                ),
                              ),
                              onMakeOffer: () async {
                                final offerPrice = await Navigator.of(context)
                                    .push<int>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DriverCounterOfferScreen(
                                              request: r,
                                            ),
                                      ),
                                    );
                                if (offerPrice != null) {
                                  _sendOffer(r, offerPrice);
                                }
                              },
                            );
                          },
                        ),
                )
              else
                const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge();

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return ValueListenableBuilder<ConnectionStatus>(
      valueListenable: RealtimeService.instance.status,
      builder: (context, status, _) {
        final connected = status == ConnectionStatus.connected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: connected ? p.safe : p.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                connected ? 'LIVE' : '…',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  color: connected ? p.safe : p.muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RideRequest request;
  final bool bidRaised;
  final VoidCallback onDismiss;
  final VoidCallback onMakeOffer;
  const _RequestCard({
    required this.request,
    required this.bidRaised,
    required this.onDismiss,
    required this.onMakeOffer,
  });

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: p.surface2,
                child: Text(
                  request.riderInitials,
                  style: TextStyle(
                    color: p.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.riderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${request.distanceKm} km · ${request.pickup} → ${request.dropoff}',
                      style: TextStyle(fontSize: 11.5, color: p.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${request.proposedPrice}',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: p.ink,
                    ),
                  ),
                  if (bidRaised)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'BID RAISED',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(request.rideType.icon, size: 13, color: p.accent),
                const SizedBox(width: 5),
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
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: onDismiss,
                  child: const Text('Not interested'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    backgroundColor: p.safe,
                    foregroundColor: p.safeInk,
                  ),
                  onPressed: onMakeOffer,
                  child: const Text('Make an offer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
