import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/trail.dart';

class ActivityViewer extends StatelessWidget {
  final Trail activity;

  const ActivityViewer({super.key, required this.activity});

  List<LatLng> _cleanPoints() {
    return activity.points
        .where((p) => !p.latitude.isNaN && !p.longitude.isNaN)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final points = _cleanPoints();

    if (points.length < 2) {
      return Scaffold(
        appBar: AppBar(title: Text(activity.name)),
        body: Center(
          child: Text(
            "Not enough GPS data to display.\n"
            "Points: ${points.length}\n"
            "Distance: ${(activity.distanceMeters / 1000).toStringAsFixed(2)} km",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final bounds = LatLngBounds.fromPoints(points);

    return Scaffold(
      appBar: AppBar(title: Text(activity.name)),
      body: Column(
        children: [
          // STATS BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blueGrey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat("Distance",
                    "${(activity.distanceMeters / 1000).toStringAsFixed(2)} km"),
                _stat("Start",
                    "${activity.startTime.hour}:${activity.startTime.minute.toString().padLeft(2,'0')}"),
                _stat(
                    "End",
                    activity.endTime == null
                        ? "--"
                        : "${activity.endTime!.hour}:${activity.endTime!.minute.toString().padLeft(2, '0')}"),
              ],
            ),
          ),

          // MAP VIEWER
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: bounds.center,
                initialZoom: 13,
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
                      points: points,
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: points.first,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.flag,
                          color: Colors.green, size: 30),
                    ),
                    Marker(
                      point: points.last,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.stop,
                          color: Colors.red, size: 30),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
