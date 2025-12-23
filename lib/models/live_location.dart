import 'package:latlong2/latlong.dart';

class LiveLocation {
  final String userId;
  final LatLng position;
  final DateTime updatedAt;

  LiveLocation({
    required this.userId,
    required this.position,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'lat': position.latitude,
        'lng': position.longitude,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory LiveLocation.fromJson(Map<String, dynamic> json) => LiveLocation(
        userId: json['userId'] as String,
        position: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          json['updatedAt'] as int? ?? 0,
        ),
      );
}
