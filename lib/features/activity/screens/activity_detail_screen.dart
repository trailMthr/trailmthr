// lib/features/activity/screens/activity_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../data/activity_db.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({
    super.key,
    required this.activityId,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Future<_ActivityDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadActivity();
  }

  Future<_ActivityDetailData> _loadActivity() async {
    final activity =
        await ActivityDb.instance.getActivityById(widget.activityId);
    final points =
        await ActivityDb.instance.getTrackPoints(widget.activityId);

    return _ActivityDetailData(
      activity: activity,
      points: points,
    );
  }

  String _formatDate(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('MMM d, y • h:mm a').format(dt);
  }

  String _formatDistance(dynamic meters) {
    final m = (meters ?? 0.0) as num;
    final miles = m / 1609.344;
    return "${miles.toStringAsFixed(2)} mi";
  }

  String _formatDuration(dynamic seconds) {
    final s = ((seconds ?? 0.0) as num).toInt();
    final d = Duration(seconds: s);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final sec = d.inSeconds.remainder(60);
    if (h > 0) {
      return "${h}h ${m}m";
    } else if (m > 0) {
      return "${m}m ${sec}s";
    } else {
      return "${sec}s";
    }
  }

  String _formatPace(dynamic paceMinPerMile) {
    final p = (paceMinPerMile ?? 0.0) as num;
    if (p <= 0) return "-";
    final minutes = p.floor();
    final seconds = ((p - minutes) * 60).round();
    final secStr = seconds.toString().padLeft(2, '0');
    return "$minutes:$secStr /mi";
  }

  @override
  Widget build(BuildContext context) {
    final Color earthDark = const Color(0xFF1E1B18);
    final Color earthMedium = const Color(0xFF3C342B);
    final Color earthLight = const Color(0xFFDAC7A1);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: earthDark,
        title: const Text("Activity Detail"),
      ),
      body: FutureBuilder<_ActivityDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading activity",
                style: TextStyle(color: earthLight),
              ),
            );
          }

          final data = snapshot.data!;
          final activity = data.activity;
          final points = data.points;

          if (activity == null) {
            return Center(
              child: Text(
                "Activity not found",
                style: TextStyle(color: earthLight),
              ),
            );
          }

          final startMillis = (activity['start_time'] as int?) ?? 0;
          final distance = activity['distance_m'];
          final duration = activity['duration_s'];
          final pace = activity['avg_pace_min_per_mile'];
          final name = (activity['name'] ?? "TrailMthr Activity").toString();

          final List<LatLng> trackPoints = points
              .map(
                (p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ),
              )
              .toList();

          LatLng? center;
          if (trackPoints.isNotEmpty) {
            center = trackPoints[trackPoints.length ~/ 2];
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Stats card
              Card(
                color: earthMedium.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: earthLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(startMillis),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statChip(
                            label: "Distance",
                            value: _formatDistance(distance),
                            earthLight: earthLight,
                          ),
                          const SizedBox(width: 8),
                          _statChip(
                            label: "Duration",
                            value: _formatDuration(duration),
                            earthLight: earthLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statChip(
                            label: "Pace",
                            value: _formatPace(pace),
                            earthLight: earthLight,
                          ),
                          const SizedBox(width: 8),
                          _statChip(
                            label: "Points",
                            value: "${points.length}",
                            earthLight: earthLight,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Map preview
              if (center != null && trackPoints.length > 1)
                SizedBox(
                  height: 260,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: "com.trailmthr.app",
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: trackPoints,
                              strokeWidth: 4,
                              color: Colors.blueAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: earthMedium.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Not enough GPS points recorded to show a route map.",
                      style: TextStyle(
                        color: earthLight.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Delete button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text("Delete this activity?"),
                          content: const Text(
                              "This will remove the activity and its GPS track."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      await ActivityDb.instance
                          .deleteActivity(widget.activityId);
                      if (!mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Delete activity"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    required Color earthLight,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: earthLight.withOpacity(0.7),
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: earthLight,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityDetailData {
  final Map<String, dynamic>? activity;
  final List<Map<String, dynamic>> points;

  _ActivityDetailData({
    required this.activity,
    required this.points,
  });
}
