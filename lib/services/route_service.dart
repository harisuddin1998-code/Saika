import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Fetches a real, road-snapped driving path between two points from the
/// free public OSRM routing server (no API key). Falls back to a straight
/// line between the two points if the request fails, so the map never ends
/// up with no line on it — e.g. offline during a demo.
Future<List<LatLng>> fetchRoadRoute(LatLng start, LatLng end) async {
  final straightLine = [start, end];
  final url = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/'
    '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
    '?overview=full&geometries=geojson',
  );
  try {
    final res = await http.get(url).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return straightLine;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) return straightLine;
    final geometry =
        (routes.first as Map<String, dynamic>)['geometry']
            as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List;
    final points = coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    return points.length > 1 ? points : straightLine;
  } catch (_) {
    return straightLine;
  }
}
