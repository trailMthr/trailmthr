// lib/features/activity/controllers/activity_recorder.dart

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/activity_repository.dart';
import '../models/tracking_mode.dart';

import 'package:trailmthr_test2/features/thinkspace/data/thinkspace_repository.dart';
import 'package:trailmthr_test2/core/trail_objects/trail_object.dart';
import 'package:uuid/uuid.dart';


import 'package:flutter/foundation.dart';

class RecorderState {
  final bool isRecording;
  final bool isPaused;
  final String? activityId;
  final List<LatLng> polyline;
  final double distanceM;
  final double durationS;
  final TrackingMode mode;

  const RecorderState({
    required this.isRecording,
    required this.isPaused,
    required this.polyline,
    required this.distanceM,
    required this.durationS,
    required this.mode,
    this.activityId,
  });

  RecorderState copyWith({
    bool? isRecording,
    bool? isPaused,
    String? activityId,
    List<LatLng>? polyline,
    double? distanceM,
    double? durationS,
    TrackingMode? mode,
  }) {
    return RecorderState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      activityId: activityId ?? this.activityId,
      polyline: polyline ?? this.polyline,
      distanceM: distanceM ?? this.distanceM,
      durationS: durationS ?? this.durationS,
      mode: mode ?? this.mode,
    );
  }

  factory RecorderState.initial() {
    return const RecorderState(
      isRecording: false,
      isPaused: false,
      activityId: null,
      polyline: [],
      distanceM: 0.0,
      durationS: 0.0,
      mode: TrackingMode.walk,
    );
  }
}

class ActivityRecorder extends ChangeNotifier {
  ActivityRecorder(this._repo, this.thinkRepo);

  final ActivityRepository _repo;
  final ThinkSpaceRepository thinkRepo;

  final Distance _distance = const Distance();

  final _stateController = StreamController<RecorderState>.broadcast();
  Stream<RecorderState> get stateStream => _stateController.stream;
  RecorderState _state = RecorderState.initial();

  StreamSubscription<Position>? _positionSub;
bool get hasActiveStream => _positionSub != null;
//
bool get canResumeSafely {
  // Conservative rule for now
  return _positionSub != null && !_state.isRecording;
}

  String? _activityId;
  DateTime? _startTime;

  DateTime? _lastPointTime;
  LatLng? _lastPointPos;
  double? _lastAlt;

  // ------------------------------------------------------------
  // PUBLIC API
  // ------------------------------------------------------------

  Future<void> start({
    TrackingMode mode = TrackingMode.walk,
    String? customName,
  }) async {
    if (_state.isRecording) return;

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();

    _activityId = id;
    _startTime = now;
    _lastPointTime = null;
    _lastPointPos = null;
    _lastAlt = null;

    // ✅ TrailObject: activity_start (no activity_id needed yet; we can include it though since we already generated it)
    await thinkRepo.insertTrailObject(
      TrailObject(
        id: const Uuid().v4(),
        type: 'activity_start',
        timestamp: now,
        lat: null,
        lng: null,
        source: 'system',
        payload: {
          'activity_id': id,
          'mode': mode.name,
        },
      ),
    );

    final name = customName ?? _defaultNameForMode(mode);
    final type = _typeForMode(mode);

    final activityMap = {
      'id': id,
      'name': name,
      'type': type,
      'start_time': now.millisecondsSinceEpoch,
      'end_time': null,
      'distance_m': 0.0,
      'duration_s': 0.0,
      'avg_pace_min_per_mile': 0.0,
      'notes': null,
    };

    await _repo.createActivity(activityMap);

    _state = RecorderState.initial().copyWith(
      isRecording: true,
      isPaused: false,
      activityId: id,
      mode: mode,
    );
    _emit();

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(_onPosition);
  }

  void pause() {
    if (!_state.isRecording || _state.isPaused) return;
    _state = _state.copyWith(isPaused: true);
    _emit();
  }

void unpause() {
  if (!_state.isRecording || !_state.isPaused) return;
  _state = _state.copyWith(isPaused: false);
  _emit();
}

  /// Stops recording and FINALIZES the activity (updates DB) and resets recorder state.
  /// Returns the final activity map (used by your summary UI).
  Future<Map<String, dynamic>?> finishAndSave() async {
    if (!_state.isRecording || _activityId == null || _startTime == null) {
      return null;
    }

    // stop GPS stream first
    _positionSub?.cancel();
    _positionSub = null;

    final now = DateTime.now();
    final durationS = now.difference(_startTime!).inMilliseconds / 1000.0;
    final distanceM = _state.distanceM;

    final miles = distanceM / 1609.344;
    final paceMinPerMile = (miles > 0) ? (durationS / 60.0) / miles : 0.0;

    // Update activity row
    await _repo.updateActivity(_activityId!, {
      'end_time': now.millisecondsSinceEpoch,
      'distance_m': distanceM,
      'duration_s': durationS,
      'avg_pace_min_per_mile': paceMinPerMile,
      'type': _typeForMode(_state.mode),
    });

    // ✅ TrailObject: activity_end (use last known point if available)
    await thinkRepo.insertTrailObject(
      TrailObject(
        id: const Uuid().v4(),
        type: 'activity_end',
        timestamp: now,
        lat: _lastPointPos?.latitude,
        lng: _lastPointPos?.longitude,
        source: 'system',
        payload: {
          'activity_id': _activityId!,
          'mode': _state.mode.name,
          'distance_m': distanceM,
          'duration_s': durationS,
          'avg_pace_min_per_mile': paceMinPerMile,
          'points': _state.polyline.length,
          'end_alt': _lastAlt,
        },
      ),
    );

    final activityMap = {
      'id': _activityId!,
      'start_time': _startTime!.millisecondsSinceEpoch,
      'end_time': now.millisecondsSinceEpoch,
      'distance_m': distanceM,
      'duration_s': durationS,
      'avg_pace_min_per_mile': paceMinPerMile,
      'type': _typeForMode(_state.mode),
      'mode': _state.mode.name,
    };

    _resetToIdle();
    return activityMap;
  }



//
Future<void> discardSession() async {
  await stop();
  _state = RecorderState.initial();
  notifyListeners();
}
//
Future<void> resume() async {
  await start();
}

//
Future<void> restartGpsStream() async {
  await stop();
  await start();
}
//
Future<void> finalize() async {
  // TODO: persist activity
  // TODO: ThinkSpace hook
  // TODO: health AI vault write

}

//
Future<void> finish() async {
  await finalize();

}


  /// Convenience: stop without caring about the returned map.
  Future<void> stop() async {
    await finishAndSave();
  }

  void dispose() {
    _positionSub?.cancel();
    _stateController.close();
  }

  // ------------------------------------------------------------
  // INTERNAL HELPERS
  // ------------------------------------------------------------

  void _emit() {
    _stateController.add(_state);
  }

//
void resumeFromPause() {
  if (!_state.isRecording || !_state.isPaused) return;
  _state = _state.copyWith(isPaused: false);
  _emit();
}

  void _resetToIdle() {
    _activityId = null;
    _startTime = null;
    _lastPointTime = null;
    _lastPointPos = null;
    _lastAlt = null;

    _state = RecorderState.initial();
    _emit();
  }

  void _onPosition(Position pos) async {
    if (!_state.isRecording || _state.isPaused) return;
    if (_activityId == null || _startTime == null) return;

    final mode = _state.mode;

    final thresholds = _thresholdsForMode(mode);
    final maxAccuracy = thresholds.maxAccuracyM;
    final minTimeMs = thresholds.minTimeMs;
    final minDistM = thresholds.minDistM;

    final accuracy = pos.accuracy; // meters
    if (accuracy > maxAccuracy) {
      // too poor to log
      return;
    }

    final now = DateTime.now();
    final latLng = LatLng(pos.latitude, pos.longitude);

    double distM = 0.0;
    if (_lastPointPos != null && _lastPointTime != null) {
      final dtMs =
          now.millisecondsSinceEpoch - _lastPointTime!.millisecondsSinceEpoch;
      distM = _distance(latLng, _lastPointPos!);

      if (dtMs < minTimeMs && distM < minDistM) {
        // too soon + too close = skip
        return;
      }
    }

    // --- Update state metrics (distance + duration + polyline)
    final newDistanceM = _state.distanceM + distM;
    final newDurationS =
        now.difference(_startTime!).inMilliseconds / 1000.0;

    final newPolyline = List<LatLng>.from(_state.polyline);
    newPolyline.add(latLng);

    _state = _state.copyWith(
      distanceM: newDistanceM,
      durationS: newDurationS,
      polyline: newPolyline,
    );
    _emit();

    // --- Save trackpoint to DB immediately
    try {
      await _repo.insertTrackPoint({
        'activity_id': _activityId!,
        'ts': now.millisecondsSinceEpoch,
        'lat': latLng.latitude,
        'lng': latLng.longitude,
        'alt': pos.altitude,
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error inserting trackpoint: $e');
    }

    _lastPointTime = now;
    _lastPointPos = latLng;
    _lastAlt = pos.altitude;
  }

  String _defaultNameForMode(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.walk:
        return "Hike / Walk";
      case TrackingMode.run:
        return "Trail Run";
      case TrackingMode.bike:
        return "Bike Ride";
      case TrackingMode.scooter:
        return "Scooter Ride";
      case TrackingMode.car:
        return "Drive";
      case TrackingMode.bus:
        return "Bus / Shuttle";
      case TrackingMode.train:
        return "Train Ride";
    }
  }

  String _typeForMode(TrackingMode mode) {
    // Stored in the "type" column; can later key off this for summaries
    switch (mode) {
      case TrackingMode.walk:
        return "walk";
      case TrackingMode.run:
        return "run";
      case TrackingMode.bike:
        return "bike";
      case TrackingMode.scooter:
        return "scooter";
      case TrackingMode.car:
        return "car";
      case TrackingMode.bus:
        return "bus";
      case TrackingMode.train:
        return "train";
    }
  }

  _ModeThresholds _thresholdsForMode(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.walk:
        return const _ModeThresholds(
          minTimeMs: 3000,
          minDistM: 3.0,
          maxAccuracyM: 50.0,
        );
      case TrackingMode.run:
        return const _ModeThresholds(
          minTimeMs: 1500,
          minDistM: 4.0,
          maxAccuracyM: 40.0,
        );
      case TrackingMode.bike:
        return const _ModeThresholds(
          minTimeMs: 1000,
          minDistM: 10.0,
          maxAccuracyM: 40.0,
        );
      case TrackingMode.scooter:
        return const _ModeThresholds(
          minTimeMs: 900,
          minDistM: 12.0,
          maxAccuracyM: 40.0,
        );
      case TrackingMode.car:
        return const _ModeThresholds(
          minTimeMs: 1000,
          minDistM: 25.0,
          maxAccuracyM: 80.0,
        );
      case TrackingMode.bus:
        return const _ModeThresholds(
          minTimeMs: 1200,
          minDistM: 30.0,
          maxAccuracyM: 80.0,
        );
      case TrackingMode.train:
        return const _ModeThresholds(
          minTimeMs: 800,
          minDistM: 80.0,
          maxAccuracyM: 100.0,
        );
    }
  }
}

class _ModeThresholds {
  final int minTimeMs;
  final double minDistM;
  final double maxAccuracyM;

  const _ModeThresholds({
    required this.minTimeMs,
    required this.minDistM,
    required this.maxAccuracyM,
  });
}
