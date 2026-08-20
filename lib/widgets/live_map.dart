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
class LiveMapView extends StatefulWidget {
  final double height;
  final LatLng center;
  final double zoom;
  final List<LiveMapPin> pins;
  final List<LatLng>? routePoints;
  final bool interactive;
  // When true, the camera pans to follow [center] as it changes (e.g. a
  // driver's live location) instead of staying fixed on the first frame's
  // position — without this a moving pin can walk itself off-screen.
  final bool followCenter;

  const LiveMapView({
    super.key,
    this.height = 180,
    required this.center,
    this.zoom = 14,
    this.pins = const [],
    this.routePoints,
    this.interactive = true,
    this.followCenter = false,
  });

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  final MapController _controller = MapController();

  @override
  void didUpdateWidget(covariant LiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followCenter && widget.center != oldWidget.center) {
      _controller.move(widget.center, _controller.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.all
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.saika.app',
            ),
            if (widget.routePoints != null && widget.routePoints!.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(points: widget.routePoints!, strokeWidth: 4, color: p.accent),
                ],
              ),
            MarkerLayer(
              markers: widget.pins
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
