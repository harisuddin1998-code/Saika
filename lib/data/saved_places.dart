import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class SavedPlace {
  final String label;
  final String address;
  final LatLng point;
  final IconData icon;
  const SavedPlace({
    required this.label,
    required this.address,
    required this.point,
    required this.icon,
  });
}

/// Real saved-addresses backend doesn't exist yet — starts empty rather than
/// pre-filled with placeholder places, since fake Karachi-specific entries
/// look broken for a rider anywhere else in the country. A rider builds this
/// list up themselves as they book from new places.
const savedPlaces = <SavedPlace>[];
