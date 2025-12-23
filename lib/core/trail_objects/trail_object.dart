class TrailObject {
  final String id;
  final String type; // marker, activity, idea, insight
  final DateTime timestamp;

  final double? lat;
  final double? lng;

  final Map<String, dynamic> payload;
  final String source; // user, system, ai

  TrailObject({
    required this.id,
    required this.type,
    required this.timestamp,
    this.lat,
    this.lng,
    required this.payload,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'payload': payload,
      'source': source,
    };
  }
}
