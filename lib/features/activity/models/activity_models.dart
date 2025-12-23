import 'package:latlong2/latlong.dart';

enum TrackingMode {
  adaptive,
  highRate,
  ultraBatterySave,
}

enum MovementState {
  walking,
  paused,
  stationaryNoise,
  poorFix,
}

class Activity {
  final String id;
  final String? name;
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceM;
  final double durationS;
  final double? avgPaceMinPerMile;
  final String? notes;

  Activity({
    required this.id,
    required this.type,
    required this.startTime,
    this.name,
    this.endTime,
    this.distanceM = 0,
    this.durationS = 0,
    this.avgPaceMinPerMile,
    this.notes,
  });

  Activity copyWith({
    String? name,
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceM,
    double? durationS,
    double? avgPaceMinPerMile,
    String? notes,
  }) {
    return Activity(
      id: id,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      name: name ?? this.name,
      endTime: endTime ?? this.endTime,
      distanceM: distanceM ?? this.distanceM,
      durationS: durationS ?? this.durationS,
      avgPaceMinPerMile: avgPaceMinPerMile ?? this.avgPaceMinPerMile,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'distance_m': distanceM,
      'duration_s': durationS,
      'avg_pace_min_per_mile': avgPaceMinPerMile,
      'notes': notes,
    };
  }

  static Activity fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as String,
      name: map['name'] as String?,
      type: map['type'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      distanceM: (map['distance_m'] ?? 0).toDouble(),
      durationS: (map['duration_s'] ?? 0).toDouble(),
      avgPaceMinPerMile:
          map['avg_pace_min_per_mile'] != null ? (map['avg_pace_min_per_mile'] as num).toDouble() : null,
      notes: map['notes'] as String?,
    );
  }
}

class ActivityPoint {
  final int? id;
  final String activityId;
  final DateTime timestamp;
  final LatLng position;
  final double? elevM;
  final double? accuracyM;
  final double? speedMps;
  final double? verticalSpeedMps;
  final double? headingDeg;
  final MovementState movementState;
  final int segmentIndex;
  final bool isGap;

  ActivityPoint({
    this.id,
    required this.activityId,
    required this.timestamp,
    required this.position,
    this.elevM,
    this.accuracyM,
    this.speedMps,
    this.verticalSpeedMps,
    this.headingDeg,
    this.movementState = MovementState.walking,
    this.segmentIndex = 0,
    this.isGap = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_id': activityId,
      'timestamp_ms': timestamp.millisecondsSinceEpoch,
      'lat': position.latitude,
      'lng': position.longitude,
      'elev_m': elevM,
      'accuracy_m': accuracyM,
      'speed_mps': speedMps,
      'vertical_speed_mps': verticalSpeedMps,
      'heading_deg': headingDeg,
      'movement_state': movementState.name,
      'segment_index': segmentIndex,
      'is_gap': isGap ? 1 : 0,
    };
  }

  static ActivityPoint fromMap(Map<String, dynamic> map) {
    return ActivityPoint(
      id: map['id'] as int?,
      activityId: map['activity_id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp_ms'] as int),
      position: LatLng(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      ),
      elevM: (map['elev_m'] as num?)?.toDouble(),
      accuracyM: (map['accuracy_m'] as num?)?.toDouble(),
      speedMps: (map['speed_mps'] as num?)?.toDouble(),
      verticalSpeedMps: (map['vertical_speed_mps'] as num?)?.toDouble(),
      headingDeg: (map['heading_deg'] as num?)?.toDouble(),
      movementState: MovementState.values.firstWhere(
        (e) => e.name == (map['movement_state'] as String? ?? 'walking'),
        orElse: () => MovementState.walking,
      ),
      segmentIndex: (map['segment_index'] ?? 0) as int,
      isGap: (map['is_gap'] ?? 0) == 1,
    );
  }
}
