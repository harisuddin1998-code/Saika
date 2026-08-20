import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geocode_service.dart';
import '../theme/app_theme.dart';
import 'saved_locations_screen.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialCenter;
  const MapPickerScreen({super.key, required this.initialCenter});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _center;
  String _address = 'Move the map to pin a location';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
    _resolveAddress();
  }

  Future<void> _resolveAddress() async {
    setState(() => _loading = true);
    final address = await reverseGeocode(_center);
    if (!mounted) return;
    setState(() {
      _address = address;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Pin on map')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) _center = camera.center;
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) _resolveAddress();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.saika.app',
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 34),
                child: Icon(
                  Icons.location_on,
                  size: 44,
                  color: Color(0xFFD6A24C),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECTED LOCATION',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _loading ? 'Locating…' : _address,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).pop(
                            LocationPickResult(
                              address: _address,
                              point: _center,
                            ),
                          ),
                    child: const Text('Use this location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
