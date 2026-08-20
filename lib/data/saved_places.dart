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

/// Mock frequently-used places for the rider — stands in for a real
/// saved-addresses backend until one exists.
const savedPlaces = [
  SavedPlace(
    label: 'Home',
    address: 'House 12, Street 4, DHA Phase 2, Karachi',
    point: LatLng(24.8100, 67.0450),
    icon: Icons.home_outlined,
  ),
  SavedPlace(
    label: 'Work',
    address: 'Ocean Mall, Clifton, Karachi',
    point: LatLng(24.8235, 67.0345),
    icon: Icons.work_outline,
  ),
  SavedPlace(
    label: 'Clifton Block 2',
    address: 'Clifton Block 2, Karachi',
    point: LatLng(24.8138, 67.0300),
    icon: Icons.location_on_outlined,
  ),
  SavedPlace(
    label: 'Dolmen Mall',
    address: 'Dolmen Mall, Tariq Road, Karachi',
    point: LatLng(24.8735, 67.0637),
    icon: Icons.location_on_outlined,
  ),
  SavedPlace(
    label: 'Saddar',
    address: 'Saddar Town, Karachi',
    point: LatLng(24.8546, 67.0207),
    icon: Icons.location_on_outlined,
  ),
];
