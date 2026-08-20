import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

/// Real interactive map using CARTO's light "Positron" basemap — the same
/// muted, low-clutter look ride-hailing apps like Uber/Bykea use instead of
/// the busy default OpenStreetMap colors. Free, no API key. Swap the tile
/// URL for a Mapbox/MapTiler URL (with your token) once this moves from
/// prototype to production traffic; free public tile servers are not meant
/// for high-volume production use.
class LiveMapView extends StatelessWidget {
  final double height;
  final LatLng center;
  final double zoom;
  final List<LiveMapPin> pins;
  final List<LatLng>? routePoints;
  final bool interactive;

  const LiveMapView({
    super.key,
    this.height = 180,
    required this.center,
    this.zoom = 14,
    this.pins = const [],
    this.routePoints,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.saika.app',
            ),
            if (routePoints != null && routePoints!.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(points: routePoints!, strokeWidth: 4, color: p.accent),
                ],
              ),
            MarkerLayer(
              markers: pins
                  .map(
                    (pin) => Marker(
                      point: pin.point,
                      width: 34,
                      height: 34,
                      child: _PinDot(color: pin.color, icon: pin.icon),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveMapPin {
  final LatLng point;
  final Color color;
  final IconData? icon;
  const LiveMapPin({required this.point, required this.color, this.icon});
}

class _PinDot extends StatelessWidget {
  final Color color;
  final IconData? icon;
  const _PinDot({required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
      ),
      alignment: Alignment.center,
      child: icon != null ? Icon(icon, size: 14, color: Colors.white) : null,
    );
  }
}

/// Karachi reference points used across the prototype's mock data.
class KarachiPoints {
  static const clifton = LatLng(24.8138, 67.0300);
  static const tariqRoad = LatLng(24.8735, 67.0637);
  static const saddar = LatLng(24.8546, 67.0207);
}
