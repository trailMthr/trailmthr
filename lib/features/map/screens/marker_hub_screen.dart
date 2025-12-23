import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../data/saved_place_db.dart';

import 'dart:math';

class MarkerHubScreen extends StatefulWidget {
  final ll.LatLng mapCenter;

  const MarkerHubScreen({
    super.key,
    required this.mapCenter,
  });

  @override
  State<MarkerHubScreen> createState() => _MarkerHubScreenState();
}

class _MarkerHubScreenState extends State<MarkerHubScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String? _activeTypeFilter;
  List<Map<String, dynamic>> _allMarkers = [];
  List<Map<String, dynamic>> _filteredMarkers = [];

double _radiusKm = 5.0; // ✅ default 5 km

double _distanceKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const earthRadius = 6371; // km

  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);

  final a =
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          (sin(dLng / 2) * sin(dLng / 2));

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _degToRad(double deg) {
  return deg * (pi / 180);
}

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  // ------------------------------------------------------------
  // LOAD MARKERS FROM DB
  // ------------------------------------------------------------
  Future<void> _loadMarkers() async {
    final rows = await SavedPlaceDb.instance.getAllPlaces();

    if (!mounted) return;

    setState(() {
      _allMarkers = rows;
      _filteredMarkers = rows;
    });
  }

  // ------------------------------------------------------------
  // SEARCH + FILTER ENGINE
  // ------------------------------------------------------------
void _applySearchAndFilter() {
  final q = _searchCtrl.text.toLowerCase();

  setState(() {
    _filteredMarkers = _allMarkers.where((m) {
      final name = (m["name"] ?? "").toString().toLowerCase();
      final notes = (m["notes"] ?? "").toString().toLowerCase();
      final type = (m["type"] ?? "").toString().toLowerCase();

      final matchesSearch =
          q.isEmpty || name.contains(q) || notes.contains(q) || type.contains(q);

      final matchesType =
          _activeTypeFilter == null || type == _activeTypeFilter;

      // ✅ DISTANCE FILTER
      final lat = (m["lat"] as num?)?.toDouble();
      final lng = (m["lng"] as num?)?.toDouble();

      if (lat == null || lng == null) return false;

      final distKm = _distanceKm(
        widget.mapCenter.latitude,
        widget.mapCenter.longitude,
        lat,
        lng,
      );

      final withinRadius = distKm <= _radiusKm;

      return matchesSearch && matchesType && withinRadius;
    }).toList();
  });
}


  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Markers"),
      ),
      body: Column(
        children: [
          // ✅ SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search markers…",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applySearchAndFilter();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => _applySearchAndFilter(),
            ),
          ),

          // ✅ TYPE FILTER CHIPS
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildFilterChip(null, "All"),
                _buildFilterChip("camp", "Camp"),
                _buildFilterChip("water", "Water"),
                _buildFilterChip("view", "Views"),
                _buildFilterChip("hazard", "Hazards"),
                _buildFilterChip("whisper", "Whispers"),
                _buildFilterChip("poi", "POIs"),
              ],
            ),
          ),

Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Radius: ${_radiusKm.toStringAsFixed(1)} km",
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      Slider(
        value: _radiusKm,
        min: 0.1,
        max: 50,
        divisions: 100,
        label: "${_radiusKm.toStringAsFixed(1)} km",
        onChanged: (v) {
          setState(() => _radiusKm = v);
          _applySearchAndFilter();
        },
      ),
    ],
  ),
),

          const Divider(height: 1),

          // ✅ FILTERED MARKER LIST
          Expanded(
            child: _filteredMarkers.isEmpty
                ? const Center(
                    child: Text("No markers found"),
                  )
                : ListView.builder(
                    itemCount: _filteredMarkers.length,
                    itemBuilder: (context, index) {
                      final place = _filteredMarkers[index];
                      return _markerListTile(place);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FILTER CHIP
  // ------------------------------------------------------------
  Widget _buildFilterChip(String? type, String label) {
    final selected = _activeTypeFilter == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) {
          setState(() {
            _activeTypeFilter = v ? type : null;
          });
          _applySearchAndFilter();
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // MARKER LIST TILE
  // ------------------------------------------------------------
  Widget _markerListTile(Map<String, dynamic> place) {
    final type = place["type"] ?? "other";
    final name = place["name"] ?? "Unnamed";

    return ListTile(
      leading: Icon(_markerTypeIcon(type)),
      title: Text(name),
      subtitle: Text(type.toString()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context, place); // return selected marker if needed
      },
    );
  }

  // ------------------------------------------------------------
  // ICON MAPPER (SAFE)
  // ------------------------------------------------------------
  IconData _markerTypeIcon(String type) {
    switch (type) {
      case "camp":
        return Icons.local_fire_department;
      case "water":
        return Icons.water_drop;
      case "view":
        return Icons.visibility;
      case "hazard":
        return Icons.warning;
      case "whisper":
        return Icons.forum;
      case "poi":
        return Icons.star;
      default:
        return Icons.place;
    }
  }
}
