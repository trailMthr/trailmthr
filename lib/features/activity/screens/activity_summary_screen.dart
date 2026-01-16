import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:trailmthr_test2/features/activity/data/activity_db.dart';
import 'package:trailmthr_test2/features/thinkspace/data/thinkspace_repository.dart';

class ActivitySummaryScreen extends StatefulWidget {
  final String activityId;
  final Map<String, dynamic>? activity;
  final ThinkSpaceRepository? thinkRepo;

  const ActivitySummaryScreen({
    super.key,
    required this.activityId,
    this.activity,
    this.thinkRepo,
  });

  @override
  State<ActivitySummaryScreen> createState() =>
      _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen> {
  List<List<LatLng>> _segments = [];
  bool _loading = true;

  // fallback if activity map not passed
  Map<String, dynamic> get _activity =>
      widget.activity ?? {};

  @override
  void initState() {
    super.initState();
    _loadTrack();
  }

  Future<void> _loadTrack() async {
    final points =
        await ActivityDb.instance.getTrackPoints(widget.activityId);

    if (points.isEmpty) {
      setState(() {
        _segments = [];
        _loading = false;
      });
      return;
    }

    List<List<LatLng>> segments = [];
    List<LatLng> current = [];

    int? lastTs;

    for (final p in points) {
      final ts = p['ts'] as int;
      final lat = (p['lat'] as num).toDouble();
      final lng = (p['lng'] as num).toDouble();

      if (lastTs != null && ts - lastTs > 3000) {
        if (current.isNotEmpty) segments.add(current);
        current = [];
      }

      current.add(LatLng(lat, lng));
      lastTs = ts;
    }

    if (current.isNotEmpty) segments.add(current);

    setState(() {
      _segments = segments;
      _loading = false;
    });
  }

  // ------------------------------------------------------------
  // THINKSPACE
  // ------------------------------------------------------------
  Future<void> _addToThinkSpace() async {
    final a = _activity;

    if (widget.thinkRepo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ThinkSpace not available")),
      );
      return;
    }

    final distanceMiles =
        ((a['distance_m'] ?? 0) / 1609.344);
    final durationMin =
        ((a['duration_s'] ?? 0) / 60).round();

    final summary =
        "${a['name'] ?? 'Activity'} — "
        "${distanceMiles.toStringAsFixed(2)} mi, "
        "$durationMin min";

    await widget.thinkRepo!.createNode(
      type: 'activity',
      content: summary,
      activityId: a['id'],
      lifecycleState: 'idea',
      functionType: 'summary',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to ThinkSpace")),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final a = _activity;

    final double distanceM =
        (a['distance_m'] as num?)?.toDouble() ?? 0.0;
    final double durationS =
        (a['duration_s'] as num?)?.toDouble() ?? 0.0;
    final double avgPace =
        (a['avg_pace_min_per_mile'] as num?)?.toDouble() ?? 0.0;

    final double distanceMiles = distanceM / 1609.344;
    final duration = Duration(seconds: durationS.toInt());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity Summary"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ------------------------------------------------------------
              // 📍 MAP
              // ------------------------------------------------------------
              SizedBox(
                height: 280,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _segments.isEmpty
                        ? const Center(
                            child: Text("No GPS track recorded"))
                        : _buildMapView(),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------------------
              // STATS
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatCard(
                      title: "Distance",
                      value:
                          "${distanceMiles.toStringAsFixed(2)} mi",
                    ),
                    _StatCard(
                      title: "Duration",
                      value: _formatDuration(duration),
                    ),
                    _StatCard(
                      title: "Avg Pace",
                      value: avgPace == 0
                          ? "—"
                          : "${avgPace.toStringAsFixed(1)} min/mi",
                    ),

                    const SizedBox(height: 24),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.psychology),
                      label: const Text("Add to ThinkSpace"),
                      onPressed: _addToThinkSpace,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // MAP WIDGET
  // ------------------------------------------------------------
  Widget _buildMapView() {
    final all = _segments.expand((s) => s).toList();

    final avgLat = all.map((p) => p.latitude)
        .reduce((a, b) => a + b) / all.length;
    final avgLng = all.map((p) => p.longitude)
        .reduce((a, b) => a + b) / all.length;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(avgLat, avgLng),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.trailmthr.app',
        ),

        // 🔹 Split segments to show GPS gaps
        PolylineLayer(
          polylines: _segments.map((seg) {
            return Polyline(
              points: seg,
              strokeWidth: 4,
              color: Colors.blueAccent,
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) return "${h}h ${m}m ${s}s";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }
}

// ---------------------------------------------------------------------------
// UI COMPONENTS
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
