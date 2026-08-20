import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/active_trip.dart';
import '../models/ride_request.dart';
import '../models/rider_identity.dart';
import '../services/fare_calculator.dart';
import '../services/geocode_service.dart';
import '../services/realtime_service.dart';
import '../theme/app_theme.dart';
import '../widgets/saika_wallpaper.dart';
import '../widgets/live_map.dart';
import 'app_drawer.dart';
import 'bidding_screen.dart';
import 'saved_locations_screen.dart';
import 'trip_screen.dart';

/// Fallback map center used only until the rider's real location resolves
/// (or if they deny location permission) — a rough geographic center of
/// Pakistan, not any specific city, so the app doesn't quietly assume every
/// rider is in Karachi.
const _fallbackCenter = LatLng(30.3753, 69.3451);

class _RideTypeMeta {
  final String label;
  final String hint;
  final IconData icon;
  const _RideTypeMeta({
    required this.label,
    required this.hint,
    required this.icon,
  });
}

const _rideTypeMeta = {
  RideType.solo: _RideTypeMeta(
    label: '1 Person',
    hint: 'Solo ride',
    icon: Icons.person_outline,
  ),
  RideType.couple: _RideTypeMeta(
    label: 'Couple',
    hint: 'Up to 2',
    icon: Icons.people_outline,
  ),
  RideType.family: _RideTypeMeta(
    label: 'Family',
    hint: 'Up to 4',
    icon: Icons.family_restroom,
  ),
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  RideType _rideType = RideType.solo;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String _driverPreference = 'female';

  static const _dropPlaceholder = 'Choose your drop-off';

  String _pickupAddress = 'Detecting your location…';
  LatLng _pickupPoint = _fallbackCenter;
  String _dropAddress = _dropPlaceholder;
  LatLng _dropPoint = _fallbackCenter;
  bool _pickupSet = false;
  bool _dropSet = false;
  bool _locating = false;

  bool get _readyToSearch => _pickupSet && _dropSet;

  late double _distanceKm = _computeDistance();
  late int _price = FareCalculator.fareFor(_distanceKm, _rideType);

  double _computeDistance() =>
      const Distance().as(LengthUnit.Kilometer, _pickupPoint, _dropPoint);

  int get _minPrice => FareCalculator.minFareFor(_distanceKm, _rideType);

  @override
  void initState() {
    super.initState();
    _useCurrentLocationForPickup(silent: true);
  }

  Future<void> _useCurrentLocationForPickup({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          !await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          if (_pickupAddress == 'Detecting your location…') {
            _pickupAddress = 'Set your pickup location';
          }
        });
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turn on location permission to find you on the map.'),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LatLng(pos.latitude, pos.longitude);
      final address = await reverseGeocode(point);
      if (!mounted) return;
      setState(() {
        _pickupPoint = point;
        _pickupAddress = address;
        _pickupSet = true;
        _distanceKm = _computeDistance();
        _price = FareCalculator.fareFor(_distanceKm, _rideType);
      });
    } catch (_) {
      if (!mounted) return;
      if (_pickupAddress == 'Detecting your location…') {
        setState(() => _pickupAddress = 'Set your pickup location');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _adjust(int delta) {
    setState(() => _price = (_price + delta).clamp(_minPrice, 5000));
  }

  void _selectRideType(RideType type) {
    setState(() {
      _rideType = type;
      _price = FareCalculator.fareFor(_distanceKm, type);
    });
  }

  Future<void> _pickLocation(String fieldLabel) async {
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => SavedLocationsScreen(
          fieldLabel: fieldLabel,
          initialCenter: _pickupSet ? _pickupPoint : _fallbackCenter,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (fieldLabel == 'PICKUP') {
        _pickupAddress = result.address;
        _pickupPoint = result.point;
        _pickupSet = true;
      } else {
        _dropAddress = result.address;
        _dropPoint = result.point;
        _dropSet = true;
      }
      _distanceKm = _computeDistance();
      _price = FareCalculator.fareFor(_distanceKm, _rideType);
    });
  }

  void _findDrivers() {
    final request = RideRequest(
      id: newEventId(),
      riderInitials: RiderIdentity.initials,
      riderName: RiderIdentity.name,
      pickup: _pickupAddress,
      dropoff: _dropAddress,
      distanceKm: double.parse(_distanceKm.toStringAsFixed(1)),
      proposedPrice: _price,
      pickupLat: _pickupPoint.latitude,
      pickupLng: _pickupPoint.longitude,
      dropLat: _dropPoint.latitude,
      dropLng: _dropPoint.longitude,
      rideType: _rideType,
      paymentMethod: _paymentMethod,
      requestedAtMs: DateTime.now().millisecondsSinceEpoch,
      preferredDriverGender: _driverPreference,
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BiddingScreen(request: request)));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.transparent,
      body: SaikaWallpaper(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: p.accent,
                  labelColor: p.ink,
                  unselectedLabelColor: p.muted,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  tabs: [
                    const Tab(text: 'BOOK A RIDE'),
                    Tab(
                      child: ValueListenableBuilder<ActiveTrip?>(
                        valueListenable: ActiveTripStore.instance.current,
                        builder: (context, trip, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('ONGOING TRIP'),
                            if (trip != null) ...[
                              const SizedBox(width: 5),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: p.safe,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookTab(context, p),
                    _buildOngoingTab(context, p),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookTab(BuildContext context, AppPalette p) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BOOK A RIDE',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const _ConnectionBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          LiveMapView(
                            height: 190,
                            center: _pickupPoint,
                            zoom: 13.5,
                            followCenter: true,
                            pins: [
                              LiveMapPin(
                                point: _pickupPoint,
                                color: const Color(0xFFD6A24C),
                                icon: Icons.my_location,
                              ),
                              LiveMapPin(
                                point: _dropPoint,
                                color: const Color(0xFF4FAE7A),
                                icon: Icons.flag,
                              ),
                            ],
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Builder(
                              builder: (context) => _MenuButton(
                                onTap: () => Scaffold.of(context).openDrawer(),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: _LocateButton(
                              locating: _locating,
                              onTap: () => _useCurrentLocationForPickup(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Field(
                        label: 'PICKUP',
                        value: _pickupAddress,
                        onTap: () => _pickLocation('PICKUP'),
                      ),
                      const SizedBox(height: 8),
                      _Field(
                        label: 'DROP-OFF',
                        value: _dropAddress,
                        onTap: () => _pickLocation('DROP-OFF'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'RIDE TYPE',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final type in RideType.values) ...[
                            Expanded(
                              child: _RideTypeCard(
                                meta: _rideTypeMeta[type]!,
                                selected: _rideType == type,
                                onTap: () => _selectRideType(type),
                              ),
                            ),
                            if (type != RideType.values.last)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'DRIVER PREFERENCE',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _DriverPrefCard(
                              label: 'Female driver',
                              hint: 'Wait for a woman',
                              icon: Icons.woman_outlined,
                              selected: _driverPreference == 'female',
                              onTap: () =>
                                  setState(() => _driverPreference = 'female'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DriverPrefCard(
                              label: 'Any driver',
                              hint: 'Incl. verified men 45-50',
                              icon: Icons.people_alt_outlined,
                              selected: _driverPreference == 'any',
                              onTap: () =>
                                  setState(() => _driverPreference = 'any'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.accent),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'YOUR PRICE',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StepButton(
                                  icon: Icons.remove,
                                  onTap: _price <= _minPrice
                                      ? null
                                      : () => _adjust(-25),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    'Rs $_price',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: p.accent,
                                    ),
                                  ),
                                ),
                                _StepButton(
                                  icon: Icons.add,
                                  onTap: () => _adjust(25),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _price <= _minPrice
                                  ? 'Minimum — covers fuel + maintenance, can\'t go lower'
                                  : '${_distanceKm.toStringAsFixed(1)} km · fuel + maintenance + her earning',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: _price <= _minPrice ? p.sos : p.muted,
                                fontWeight: _price <= _minPrice
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Builder(
                              builder: (context) {
                                final b = FareCalculator.breakdownFor(
                                  _distanceKm,
                                  _rideType,
                                );
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _FareChip(
                                      label: 'Fuel',
                                      value: b.fuel,
                                      color: p.muted,
                                    ),
                                    _FareChip(
                                      label: 'Maint.',
                                      value: b.maintenance,
                                      color: p.muted,
                                    ),
                                    _FareChip(
                                      label: 'Her earning',
                                      value: b.profit,
                                      color: p.safe,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'PAYMENT METHOD',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final method in PaymentMethod.values)
                            _PaymentChip(
                              method: method,
                              selected: _paymentMethod == method,
                              onTap: () =>
                                  setState(() => _paymentMethod = method),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: FilledButton(
            onPressed: _readyToSearch ? _findDrivers : null,
            child: Text(
              _readyToSearch ? 'Find a Driver' : 'Set pickup & drop-off first',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOngoingTab(BuildContext context, AppPalette p) {
    return ValueListenableBuilder<ActiveTrip?>(
      valueListenable: ActiveTripStore.instance.current,
      builder: (context, trip, _) {
        if (trip == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_taxi_outlined,
                    size: 40,
                    color: p.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No ongoing trip',
                    style: TextStyle(
                      color: p.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Book a ride from the "Book a Ride" tab and it\'ll show up here while it\'s active.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final driver = trip.driver;
        final request = trip.request;
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          Text(
                            driver.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            trip.arrived
                                ? '${driver.carModel} · ${driver.plate} · Arrived'
                                : '${driver.carModel} · ${driver.plate} · On the way',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: trip.arrived ? p.safeInk : p.muted,
                              fontWeight: trip.arrived
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
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.pickup} → ${request.dropoff}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.distanceKm.toStringAsFixed(1)} km · Rs ${driver.price}',
                      style: TextStyle(fontSize: 11.5, color: p.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TripScreen(driver: driver, request: request),
                  ),
                ),
                child: const Text('View full trip'),
              ),
            ],
          ),
        );
      },
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
        return Row(
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
              connected ? 'LIVE' : 'CONNECTING…',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.5,
                letterSpacing: 0.6,
                color: connected ? p.safe : p.muted,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _Field({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: p.muted),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.menu, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}

class _LocateButton extends StatelessWidget {
  final bool locating;
  final VoidCallback onTap;
  const _LocateButton({required this.locating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: locating ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: locating
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: p.accent,
                  ),
                )
              : Icon(Icons.my_location, size: 20, color: p.accent),
        ),
      ),
    );
  }
}

class _RideTypeCard extends StatelessWidget {
  final _RideTypeMeta meta;
  final bool selected;
  final VoidCallback onTap;
  const _RideTypeCard({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.14) : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? p.accent : p.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(meta.icon, size: 19, color: selected ? p.accent : p.muted),
            const SizedBox(height: 4),
            Text(
              meta.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? p.accent : p.ink,
              ),
            ),
            const SizedBox(height: 1),
            Text(meta.hint, style: TextStyle(fontSize: 9.5, color: p.muted)),
          ],
        ),
      ),
    );
  }
}

class _DriverPrefCard extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _DriverPrefCard({
    required this.label,
    required this.hint,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.14) : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? p.accent : p.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: selected ? p.accent : p.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: selected ? p.accent : p.ink,
                    ),
                  ),
                  Text(
                    hint,
                    style: TextStyle(fontSize: 9, color: p.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FareChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _FareChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Rs $value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final disabled = onTap == null;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: disabled ? p.surface2.withValues(alpha: 0.4) : p.surface2,
          shape: BoxShape.circle,
          border: Border.all(color: p.line),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 15, color: disabled ? p.muted : p.ink),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentChip({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.16) : p.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? p.accent : p.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(method.icon, size: 16, color: selected ? p.accent : p.muted),
            const SizedBox(width: 7),
            Text(
              method.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: selected ? p.accent : p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
