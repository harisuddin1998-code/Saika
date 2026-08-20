import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../data/saved_places.dart';
import '../services/geocode_service.dart';
import '../theme/app_theme.dart';
import 'map_picker_screen.dart';

class LocationPickResult {
  final String address;
  final LatLng point;
  const LocationPickResult({required this.address, required this.point});
}

class SavedLocationsScreen extends StatefulWidget {
  final String fieldLabel;
  const SavedLocationsScreen({super.key, required this.fieldLabel});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  int? _selected;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  List<({String address, LatLng point})> _results = [];

  bool get _isSearching => _searchCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _searching = true);
      final results = await searchAddress(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    });
  }

  Future<void> _pickFromMap() async {
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initialCenter: savedPlaces.first.point),
      ),
    );
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final isPickup = widget.fieldLabel == 'PICKUP';
    return Scaffold(
      appBar: AppBar(title: Text('Select ${isPickup ? 'pickup' : 'drop-off'}')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: p.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        style: TextStyle(fontSize: 13.5, color: p.ink),
                        decoration: InputDecoration(
                          hintText: 'Search address',
                          hintStyle: TextStyle(color: p.muted, fontSize: 13.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    if (_isSearching)
                      InkWell(
                        onTap: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                        child: Icon(Icons.close, size: 18, color: p.muted),
                      ),
                  ],
                ),
              ),
            ),
            if (_isSearching)
              Expanded(
                child: _searching
                    ? Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: p.accent,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : _results.isEmpty
                    ? Center(
                        child: Text(
                          'No matching address found',
                          style: TextStyle(color: p.muted, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final r = _results[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).pop(
                              LocationPickResult(
                                address: r.address,
                                point: r.point,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: p.line),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 20,
                                    color: p.muted,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      r.address,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: p.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              )
            else ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickFromMap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.accent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.map_outlined, size: 18, color: p.accent),
                        const SizedBox(width: 10),
                        Text(
                          'Select from map',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: p.accent,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, size: 18, color: p.accent),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SAVED & FREQUENT PLACES',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  itemCount: savedPlaces.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final place = savedPlaces[i];
                    final selected = _selected == i;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selected = i),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? p.accent.withValues(alpha: 0.12)
                              : p.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? p.accent : p.line,
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              place.icon,
                              size: 20,
                              color: selected ? p.accent : p.muted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: p.ink,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    place.address,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: p.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle,
                                color: p.accent,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(
                          LocationPickResult(
                            address: savedPlaces[_selected!].address,
                            point: savedPlaces[_selected!].point,
                          ),
                        ),
                  child: const Text('Go'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
