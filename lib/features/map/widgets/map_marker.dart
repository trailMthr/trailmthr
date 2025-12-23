// lib/features/map/widgets/map_marker.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/trail_point.dart';

/// Helper: create a Marker instance from a TrailPoint.
/// You may call this from MarkerLayer.markers: points.map((p) => markerFromPoint(p, onTap)).toList()
Marker markerFromPoint(
  TrailPoint point,
  void Function(TrailPoint point) onTap, {
  double size = 44,
  Color color = Colors.red,
}) {
  return Marker(
    point: point.location,
    width: size,
    height: size,
    builder: (ctx) => GestureDetector(
      onTap: () => onTap(point),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: size,
            color: color,
          ),
        ],
      ),
    ),
  );
}
