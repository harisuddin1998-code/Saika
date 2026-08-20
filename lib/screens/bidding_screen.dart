import 'dart:async';
import 'package:flutter/material.dart';
import '../models/driver_offer.dart';
import '../models/ride_request.dart';
import '../services/realtime_service.dart';
import '../theme/app_theme.dart';
import 'trip_screen.dart';

class BiddingScreen extends StatefulWidget {
  final RideRequest request;
  const BiddingScreen({super.key, required this.request});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  static const _lateThreshold = Duration(seconds: 15);
  static const _bidStep = 25;

  StreamSubscription? _sub;
  Timer? _lateTimer;
  final List<DriverOffer> _offers = [];
  DriverOffer? _chosen;
  late int _currentPrice = widget.request.proposedPrice;
  bool _isLate = false;
  bool _requestFailed = false;

  @override
  void initState() {
    super.initState();
    _sendRequest();
    _sub = RealtimeService.instance.events.listen((event) {
      // A brief connection drop mid-flow (common on mobile networks) means
      // this rider can miss the live ride_countered broadcast entirely — the
      // relay replays any offers already made on this request as part of
      // the state_snapshot every (re)connect sends, so recover them here too.
      if (event.type == 'state_snapshot') {
        final offersByRequest = (event.payload['offers'] as Map?)
            ?.cast<String, dynamic>();
        final mine = (offersByRequest?[widget.request.id] as List?) ?? const [];
        _mergeOffers(
          mine.map((raw) => (raw as Map).cast<String, dynamic>()),
        );
        return;
      }
      if (event.payload['requestId'] != widget.request.id) return;
      if (event.type != 'ride_countered') return;
      _mergeOffers([event.payload]);
    });
    _lateTimer = Timer(_lateThreshold, () {
      if (_offers.isEmpty) setState(() => _isLate = true);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _lateTimer?.cancel();
    super.dispose();
  }

  void _mergeOffers(Iterable<Map<String, dynamic>> jsons) {
    final iter = jsons.iterator;
    if (!iter.moveNext()) return;
    setState(() {
      do {
        final offer = DriverOffer.fromJson(iter.current);
        final i = _offers.indexWhere((o) => o.offerKey == offer.offerKey);
        if (i == -1) {
          _offers.add(offer);
        } else {
          _offers[i] = offer;
        }
      } while (iter.moveNext());
    });
  }

  Future<void> _sendRequest() async {
    final sent = await RealtimeService.instance.sendReliably(
      'ride_request',
      widget.request.toJson(),
    );
    if (mounted && !sent) setState(() => _requestFailed = true);
  }

  Future<void> _chooseDriver(DriverOffer offer) async {
    final sent = await RealtimeService.instance.sendReliably('ride_accepted', {
      ...offer.toJson(),
      'requestId': widget.request.id,
    });
    if (!mounted) return;
    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No connection — couldn\'t confirm this driver. Check your internet and try again.',
          ),
        ),
      );
      return;
    }
    setState(() => _chosen = offer);
  }

  void _rejectOffer(DriverOffer offer) {
    RealtimeService.instance.send('ride_offer_declined', {
      'requestId': widget.request.id,
      'driverId': offer.driverId,
    });
    setState(
      () => _offers.removeWhere((o) => o.offerKey == offer.offerKey),
    );
  }

  void _raiseBid() {
    final updated = widget.request.copyWith(
      proposedPrice: _currentPrice + _bidStep,
    );
    setState(() {
      _currentPrice = updated.proposedPrice;
      _isLate = false;
    });
    _lateTimer?.cancel();
    _lateTimer = Timer(_lateThreshold, () {
      if (_offers.isEmpty) setState(() => _isLate = true);
    });
    RealtimeService.instance.send('ride_bid_updated', updated.toJson());
  }

  Future<bool> _confirmAndCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: const Text(
          'Drivers who already sent an offer will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep waiting'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel ride'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    RealtimeService.instance.send('ride_cancelled', {
      'requestId': widget.request.id,
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    Widget body;
    if (_chosen != null) {
      body = _MatchedView(driver: _chosen!, request: widget.request);
    } else if (_offers.isNotEmpty) {
      body = _OffersListView(
        offers: _offers,
        request: widget.request,
        onChoose: _chooseDriver,
        onReject: _rejectOffer,
      );
    } else {
      body = _WaitingView(
        request: widget.request,
        palette: p,
        currentPrice: _currentPrice,
        isLate: _isLate,
        requestFailed: _requestFailed,
        onRaiseBid: _raiseBid,
        onRetry: _sendRequest,
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmAndCancel() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finding a driver'),
          actions: [
            TextButton(
              onPressed: () async {
                if (await _confirmAndCancel() && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: p.sos, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: body,
        ),
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  final RideRequest request;
  final AppPalette palette;
  final int currentPrice;
  final bool isLate;
  final bool requestFailed;
  final VoidCallback onRaiseBid;
  final VoidCallback onRetry;
  const _WaitingView({
    required this.request,
    required this.palette,
    required this.currentPrice,
    required this.isLate,
    required this.requestFailed,
    required this.onRaiseBid,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rs $currentPrice sent to nearby women drivers',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 6),
        Text(
          '${request.pickup} → ${request.dropoff}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Expanded(
          child: Center(
            child: requestFailed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 40, color: p.sos),
                      const SizedBox(height: 14),
                      Text(
                        'No connection — your request never went out.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: p.sos,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
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
                          color: p.accent,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Waiting for a driver to respond…',
                        style: TextStyle(color: p.muted, fontSize: 13),
                      ),
                      if (isLate) ...[
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: p.accent),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Taking longer than usual to find a driver.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: p.ink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Raise your offer to get matched faster.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: p.muted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: onRaiseBid,
                        icon: Icon(
                          Icons.arrow_upward,
                          size: 16,
                          color: p.accent,
                        ),
                        label: Text('Raise bid to Rs ${currentPrice + 25}'),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _MatchedView extends StatelessWidget {
  final DriverOffer driver;
  final RideRequest request;
  const _MatchedView({required this.driver, required this.request});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You\'re matched',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.safe),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: p.surface2,
                child: Text(
                  driver.initials,
                  style: TextStyle(color: p.ink, fontWeight: FontWeight.bold),
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
                      '${driver.carModel} · ${driver.carColor} · ★${driver.rating}',
                      style: TextStyle(fontSize: 11.5, color: p.muted),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs ${driver.price}',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.line),
          ),
          child: Row(
            children: [
              Icon(request.paymentMethod.icon, size: 18, color: p.accent),
              const SizedBox(width: 10),
              Text(
                'Paying by ${request.paymentMethod.label}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TripScreen(driver: driver, request: request),
            ),
          ),
          child: const Text('Continue to trip'),
        ),
      ],
    );
  }
}

class _OffersListView extends StatelessWidget {
  final List<DriverOffer> offers;
  final RideRequest request;
  final ValueChanged<DriverOffer> onChoose;
  final ValueChanged<DriverOffer> onReject;
  const _OffersListView({
    required this.offers,
    required this.request,
    required this.onChoose,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...offers]..sort((a, b) => a.price.compareTo(b.price));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sorted.length == 1
              ? '1 driver made an offer'
              : '${sorted.length} drivers made offers',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick who you\'d like to ride with',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _OfferCard(
              driver: sorted[i],
              askedPrice: request.proposedPrice,
              onChoose: () => onChoose(sorted[i]),
              onReject: () => onReject(sorted[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final DriverOffer driver;
  final int askedPrice;
  final VoidCallback onChoose;
  final VoidCallback onReject;
  const _OfferCard({
    required this.driver,
    required this.askedPrice,
    required this.onChoose,
    required this.onReject,
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
                radius: 22,
                backgroundColor: p.surface2,
                child: Text(
                  driver.initials,
                  style: TextStyle(color: p.ink, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${driver.carModel} · ${driver.carColor} · ★${driver.rating}',
                      style: TextStyle(fontSize: 11.5, color: p.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${driver.price}',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: driver.price <= askedPrice ? p.safe : p.accent,
                    ),
                  ),
                  if (driver.price != askedPrice)
                    Text(
                      'you asked Rs $askedPrice',
                      style: TextStyle(fontSize: 10, color: p.muted),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: onReject,
                  child: Text('Reject', style: TextStyle(color: p.sos)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: onChoose,
                  child: const Text('Choose this driver'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
