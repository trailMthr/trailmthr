import 'package:latlong2/latlong.dart';

class Trail {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceMeters;
  final List<LatLng> points;

  Trail({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.distanceMeters,
    required this.points,
  });

  Trail copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceMeters,
    List<LatLng>? points,
  }) {
    return Trail(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      points: points ?? this.points,
    );
  }
}
