import 'package:latlong2/latlong.dart';

class TrailRecord {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final List<LatLng> points;
  final double distanceMeters;
  final bool importedFromGarmin;

  TrailRecord({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.points,
    required this.distanceMeters,
    this.importedFromGarmin = false,
  });

  Duration get duration => endTime.difference(startTime);
}
