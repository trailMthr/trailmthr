// lib/models/trail_point.dart
import 'package:latlong2/latlong.dart';

/// A simple model that represents a point of interest on a trail.
class TrailPoint {
  final String id;
  final String title;
  final String? description;
  final LatLng location;
  final String? imageUrl; // optional for future use
  final String? type; // e.g., 'waypoint', 'trailhead', 'water'

  const TrailPoint({
    required this.id,
    required this.title,
    required this.location,
    this.description,
    this.imageUrl,
    this.type,
  });
}
