import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Reverse-geocodes a map point into a human-readable address using the
/// free OpenStreetMap Nominatim service (no API key). Falls back to raw
/// coordinates if the request fails.
Future<String> reverseGeocode(LatLng point) async {
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse'
    '?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18',
  );
  try {
    final res = await http
        .get(url, headers: {'User-Agent': 'saika-prototype/1.0'})
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return _fallback(point);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final name = data['display_name'] as String?;
    return (name == null || name.isEmpty) ? _fallback(point) : name;
  } catch (_) {
    return _fallback(point);
  }
}

String _fallback(LatLng point) =>
    'Pinned location (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';

/// Forward-geocodes a free-text query into a list of matching addresses
/// using Nominatim's free search endpoint (no API key), biased to Pakistan.
Future<List<({String address, LatLng point})>> searchAddress(
  String query,
) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const [];
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/search'
    '?format=json&q=${Uri.encodeQueryComponent(trimmed)}&limit=6&countrycodes=pk',
  );
  try {
    final res = await http
        .get(url, headers: {'User-Agent': 'saika-prototype/1.0'})
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body) as List;
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return (
        address: m['display_name'] as String,
        point: LatLng(
          double.parse(m['lat'] as String),
          double.parse(m['lon'] as String),
        ),
      );
    }).toList();
  } catch (_) {
    return const [];
  }
}
