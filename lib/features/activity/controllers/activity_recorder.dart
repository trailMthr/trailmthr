// lib/features/activity/controllers/activity_recorder.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:trailmthr_test2/core/debug_logger.dart';
import 'package:trailmthr_test2/core/trail_objects/trail_object.dart';
import 'package:trailmthr_test2/features/thinkspace/data/thinkspace_repository.dart';

import '../data/activity_repository.dart';
import '../models/tracking_mode.dart';
import '../../activity/controllers/live_activity_controller.dart';

import 'package:shared_preferences/shared_preferences.dart';


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

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  // Hook (optional): if present, it stays aligned with recorder truth.
  LiveActivityController? liveController;
//
static const _kRecHas = 'rec_has';
static const _kRecId = 'rec_activity_id';
static const _kRecStart = 'rec_start_ms';
static const _kRecMode = 'rec_mode';
static const _kRecDistance = 'rec_distance_m';
static const _kRecLat = 'rec_last_lat';
static const _kRecLng = 'rec_last_lng';
static const _kRecTs = 'rec_last_ts';
//
DateTime? _lastRecPersistAt;

Future<void> _persistRecorderSnapshotThrottled() async {
  final now = DateTime.now();
  if (_lastRecPersistAt != null &&
      now.difference(_lastRecPersistAt!) < const Duration(seconds: 2)) return;
  _lastRecPersistAt = now;
  await _persistRecorderSnapshot();
}

Future<void> _persistRecorderSnapshot() async {
  if (!_state.isRecording) return;
  if (_activityId == null || _startTime == null) return;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kRecHas, true);
  await prefs.setString(_kRecId, _activityId!);
  await prefs.setInt(_kRecStart, _startTime!.millisecondsSinceEpoch);
  await prefs.setString(_kRecMode, _state.mode.name);
  await prefs.setDouble(_kRecDistance, _state.distanceM);

  if (_lastPointPos != null && _lastPointTime != null) {
    await prefs.setDouble(_kRecLat, _lastPointPos!.latitude);
    await prefs.setDouble(_kRecLng, _lastPointPos!.longitude);
    await prefs.setInt(_kRecTs, _lastPointTime!.millisecondsSinceEpoch);
  }
}

Future<void> _clearRecorderSnapshot() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kRecHas);
  await prefs.remove(_kRecId);
  await prefs.remove(_kRecStart);
  await prefs.remove(_kRecMode);
  await prefs.remove(_kRecDistance);
  await prefs.remove(_kRecLat);
  await prefs.remove(_kRecLng);
  await prefs.remove(_kRecTs);
}

  // Debug telemetry
  int _sampleCount = 0;
  int _throttledCount = 0;
  double _avgDtMs = 0;
  double _avgAccuracy = 0;
  int _pointsSaved = 0;

  final Distance _distance = const Distance();

  final _stateController = StreamController<RecorderState>.broadcast();
  Stream<RecorderState> get stateStream => _stateController.stream;
  RecorderState _state = RecorderState.initial();

  StreamSubscription<Position>? _positionSub;
  bool get hasActiveStream => _positionSub != null;

  bool get canResumeSafely {
    // Conservative rule for now
    return _positionSub != null && !_state.isRecording;
  }
//

  // Garmin-parity gating config/state
  final _gpsCfg = const GpsGateConfig();
  final _gpsState = GpsGateState();

  String? _activityId;
  DateTime? _startTime;

  DateTime? _lastPointTime;
  LatLng? _lastPointPos;
  double? _lastAlt;

  // --- Watchdog: detects if GPS fixes stop arriving while "recording" ---
  Timer? _watchdog;
  DateTime? _lastFixAt;
  bool _isStalled = false;

  final Duration _stallAfter = const Duration(seconds: 15);
  final Duration _watchdogTick = const Duration(seconds: 3);

  Future<bool> _ensureNotificationsAllowed() async {
    if (!Platform.isAndroid) return true;

    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Android 13+ runtime permission. On older Android, this usually returns null.
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<bool> ensureRecordingReady(BuildContext context) async {
    // 1) Check permission
    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      debugPrint('TrailMthr: location permission not granted');
      return false;
    }

    // 2) Check that location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('TrailMthr: location services are OFF');
      return false;
    }

    return true;
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      DebugLogger.log({"event": "location_denied_forever"});
      return false;
    }

    final ok = perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;

    if (!ok) {
      DebugLogger.log({
        "event": "location_permission_insufficient",
        "perm": perm.toString(),
      });
    }

    return ok;
  }

  LocationSettings buildRunWalkSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: const Duration(seconds: 1),
        distanceFilter: 0, // we do filtering ourselves (consistent + debuggable)
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'TrailMthr is recording',
          notificationText: 'Tracking your activity…',
          enableWakeLock: true,
          enableWifiLock: false, // conservative
        ),
      );
    }

    // iOS (and other): high accuracy; gating handles quality.
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }
//
// ------------------------------------------------------------
// RECOVERY / INTEGRITY HELPERS
// ------------------------------------------------------------

Future<bool> hasUnfinishedActivityInDb(String activityId) {
  return _repo.hasUnfinishedActivity(activityId);
}
//
Future<bool> hasAnyTrackPointsInDb(String activityId) {
  return _repo.hasAnyTrackPoints(activityId);
}

Future<Map<String, dynamic>?> getActivityRow(String activityId) {
  return _repo.getActivityById(activityId);
}

  // ------------------------------------------------------------
  // PUBLIC API
  // ------------------------------------------------------------
Future<void> resumeFromRecovery({
  required TrackingMode mode,
  required String activityId,
  required DateTime startTime,
  required double distanceM,
  bool createIfMissing = false,
}) async {
  // Always ensure permissions (force-close restart needs this)
  final hasPerm = await _ensureLocationPermission();
  if (!hasPerm) return;

  final notifOk = await _ensureNotificationsAllowed();
  if (!notifOk) {
    DebugLogger.log({"event": "notifications_denied"});
    return;
  }


  // If already recording, ensure stream exists; if not, restart it.
  // (We can't see _positionSub here unless it's in scope; but it is.)
  _activityId = activityId;
  _startTime = startTime;

  // Reset last point to avoid catch-up spikes
  _lastPointTime = null;
  _lastPointPos = null;
  _lastAlt = null;

  // If we're not recording, flip state to recording
  if (!_state.isRecording) {
    _state = RecorderState.initial().copyWith(
      isRecording: true,
      isPaused: false,
      activityId: activityId,
      mode: mode,
      distanceM: distanceM,
      durationS: 0.0
    );
    _emit();
  } else if (_state.isPaused) {
    _state = _state.copyWith(isPaused: false);
    _emit();
  }

  // Optionally create activity if missing (recovery safety)
  if (createIfMissing) {
    final exists = await hasUnfinishedActivityInDb(activityId);
    if (!exists) {
      final name = _defaultNameForMode(mode);
      final type = _typeForMode(mode);
      final activityMap = {
        'id': activityId,
        'name': name,
        'type': type,
        'start_time': startTime.millisecondsSinceEpoch,
        'end_time': null,
        'distance_m': distanceM,
        'duration_s': 0.0,
        'avg_pace_min_per_mile': 0.0,
        'notes': null,
      };
      await _repo.createActivity(activityMap);
    }
  }

  // Restart GPS stream if needed
  final settings = buildRunWalkSettings();
  await _positionSub?.cancel();
  _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
    _onPosition,
    onError: (e) {
      DebugLogger.log({"event": "gps_error", "error": e.toString()});
    },
    cancelOnError: false,
  );
}

  Future<void> start({
    TrackingMode mode = TrackingMode.walk,
    String? customName,
    String? activityIdOverride,
    DateTime? startTimeOverride,
    double? distanceOverride,
    bool createIfMissing = true,
  }) async {
    if (_state.isRecording) return;

    // 1) Make sure we have location permission
    final hasPerm = await _ensureLocationPermission();
    if (!hasPerm) {
      // TODO: surface to UI
      return;
    }

    // 1b) Android notifications permission (helps background recording UX)
    final notifOk = await _ensureNotificationsAllowed();
    if (!notifOk) {
      DebugLogger.log({"event": "notifications_denied"});
      // TODO: surface to UI
      return;
    }

final now = DateTime.now();
final id = activityIdOverride ?? now.millisecondsSinceEpoch.toString();
final startTime = startTimeOverride ?? now;

_activityId = id;
_startTime = startTime;

    _lastPointTime = null;
    _lastPointPos = null;
    _lastAlt = null;

    _sampleCount = 0;
    _throttledCount = 0;
    _avgDtMs = 0;
    _avgAccuracy = 0;
    _pointsSaved = 0;

    _gpsState.reset();

    await DebugLogger.start(id);
    DebugLogger.log({
      "event": "activity_start",
      "mode": mode.name,
    });

    final name = customName ?? _defaultNameForMode(mode);
    final type = _typeForMode(mode);

    final activityMap = {
      'id': id,
      'name': name,
      'type': type,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': null,
      'distance_m': distanceOverride ?? 0.0,
      'duration_s': 0.0,
      'avg_pace_min_per_mile': 0.0,
      'notes': null,
    };

if (createIfMissing) {
  final exists = await hasUnfinishedActivityInDb(id);
  if (!exists) {
    await _repo.createActivity(activityMap);
  }
}



    _state = RecorderState.initial().copyWith(
      isRecording: true,
      isPaused: false,
      activityId: id,
      mode: mode,
        distanceM: distanceOverride ?? 0.0,
  durationS: distanceOverride != null 
    ? now.difference(_startTime!).inMilliseconds / 1000.0
    : 0.0,
    );
    _emit();

    // --- Watchdog init ---
    _lastFixAt = DateTime.now();
    _isStalled = false;

    _watchdog?.cancel();
    _watchdog = Timer.periodic(_watchdogTick, (_) {
      if (!_state.isRecording || _state.isPaused) return;

      final last = _lastFixAt;
      if (last == null) return;

      final stalled = DateTime.now().difference(last) > _stallAfter;
      if (stalled != _isStalled) {
        _isStalled = stalled;

        DebugLogger.log({
          "event": "gps_stall_state",
          "stalled": _isStalled,
          "since_ms": DateTime.now().difference(last).inMilliseconds,
        });

        // Hook: later you can surface this in UI via RecorderState if desired
        notifyListeners();
      }
    });

    // 2) Build platform-aware settings (single source of truth)
    final settings = buildRunWalkSettings();

    // 3) Start GPS stream
    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      _onPosition,
      onError: (e) {
        DebugLogger.log({
          "event": "gps_error",
          "error": e.toString(),
        });
      },
      cancelOnError: false,
    );
  }

void pause() {
  if (!_state.isRecording || _state.isPaused) return;

  //prevent "catch up" of duration on resume
  _lastPointPos = null;
  _lastPointTime = null;

  _state = _state.copyWith(isPaused: true);
  _emit();

  liveController?.pause(); // ✅ freezes time
}

void unpause() {
  if (!_state.isRecording || !_state.isPaused) return;

  // Reset last point to avoid "catch up" jumps
  _lastPointPos = null;
  _lastPointTime = null;

  _state = _state.copyWith(isPaused: false);
  _emit();

  liveController?.resume(); // ✅ resumes time
}

  /// Stops recording and FINALIZES the activity (updates DB) and resets recorder state.
  /// Returns the final activity map (used by your summary UI).
  Future<Map<String, dynamic>?> finishAndSave() async {
    if (!_state.isRecording || _activityId == null || _startTime == null) {
      return null;
    }

    _positionSub?.cancel();
    _positionSub = null;

    _watchdog?.cancel();
    _watchdog = null;

    final now = DateTime.now();
///////
    ///
    final durationS =
        (liveController?.elapsed.inMilliseconds ?? now.difference(_startTime!).inMilliseconds) / 1000.0;

///// Ensure recorder state reflects canonical duration on finalize.
_state = _state.copyWith(durationS: durationS);
_emit();

//////
    final distanceM = _state.distanceM;

    final miles = distanceM / 1609.344;
    final paceMinPerMile = (miles > 0) ? (durationS / 60.0) / miles : 0.0;

    await _repo.updateActivity(_activityId!, {
      'end_time': now.millisecondsSinceEpoch,
      'distance_m': distanceM,
      'duration_s': durationS,
      'avg_pace_min_per_mile': paceMinPerMile,
      'type': _typeForMode(_state.mode),
    });

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

    DebugLogger.log({
      "event": "activity_end",
      "total_m": distanceM,
      "duration_s": durationS,
      "accepted_pts": _gpsState.acceptedPts,
      "rejected_pts": _gpsState.rejectedPts,
    });

    try {
      await DebugLogger.close();
    } catch (_) {}
await _clearRecorderSnapshot();

    _resetToIdle();
    return activityMap;
  }

  Future<void> discardSession() async {
    await stop();
    await _clearRecorderSnapshot();

    _state = RecorderState.initial();
    notifyListeners();
  }

  /// IMPORTANT: this is a "resume from pause", not crash recovery.
  Future<void> resume() async {
    unpause();
  }

  Future<void> restartGpsStream() async {
    await stop();
    await start(mode: _state.mode);
  }

  Future<void> finalize() async {
    // TODO: persist activity
    // TODO: ThinkSpace hook
    // TODO: health AI vault write
  }

  Future<void> finish() async {
    await finalize();
  }

  Future<void> stop() async {
    await finishAndSave();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _positionSub?.cancel();
    _stateController.close();
    super.dispose();
  }

  // ------------------------------------------------------------
  // INTERNAL HELPERS
  // ------------------------------------------------------------

  void _emit() {
    _stateController.add(_state);
  }

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

    _gpsState.reset();

    _state = RecorderState.initial();
    _emit();
  }

  void _onPosition(Position pos) async {
    if (!_state.isRecording) return;
    if (_state.isPaused) return;
    
    if (_activityId == null || _startTime == null) return;

    final mode = _state.mode;
    final thresholds = _thresholdsForMode(mode);

    // Watchdog heartbeat
    _lastFixAt = DateTime.now();
    if (_isStalled) {
      _isStalled = false;
      notifyListeners();
    }

    final now = DateTime.now();
    _gpsState.startedAt ??= now;
    final elapsed = now.difference(_gpsState.startedAt!);

    // ---- Garmin-parity gating ----
    final acc = pos.accuracy;

    if (acc.isNaN || acc > _gpsCfg.accuracyHardCapM) {
      _gpsState.rejectedPts++;
      DebugLogger.log({
        "event": "gps_reject",
        "reason": "accuracy_hardcap",
        "acc": acc,
        "rej_pts": _gpsState.rejectedPts,
      });
      return;
    }

    final maxAcc = (elapsed <= _gpsCfg.startWindow)
        ? (thresholds.maxAccuracyM + _gpsCfg.startAccuracyRelaxM)
        : thresholds.maxAccuracyM;

    if (acc > maxAcc) {
      _gpsState.rejectedPts++;
      DebugLogger.log({
        "event": "gps_reject",
        "reason": "accuracy_gate",
        "acc": acc,
        "maxAcc": maxAcc,
        "elapsed_s": elapsed.inSeconds,
        "rej_pts": _gpsState.rejectedPts,
      });
      return;
    }

    final latLng = LatLng(pos.latitude, pos.longitude);

    double distM = 0.0;
    int? dtMs;
    double? vImp;

    if (_lastPointPos != null && _lastPointTime != null) {
      dtMs = now.millisecondsSinceEpoch - _lastPointTime!.millisecondsSinceEpoch;
      distM = _distance(latLng, _lastPointPos!);

      // Movement gate
      if (distM < thresholds.minDistM) {
        _gpsState.rejectedPts++;
        DebugLogger.log({
          "event": "gps_reject",
          "reason": "min_move",
          "dM": distM,
          "minM": thresholds.minDistM,
          "rej_pts": _gpsState.rejectedPts,
        });
        return;
      }

      // Time gate (your rule)
      if (dtMs < thresholds.minTimeMs) {
        _gpsState.rejectedPts++;
        DebugLogger.log({
          "event": "gps_reject",
          "reason": "min_time",
          "dt_ms": dtMs,
          "minTimeMs": thresholds.minTimeMs,
          "rej_pts": _gpsState.rejectedPts,
        });
        return;
      }

      // Spike rejection based on implied speed (run/walk only)
      final dtSafe = math.max(dtMs, 200) / 1000.0;
      vImp = distM / dtSafe;

      if (vImp > _gpsCfg.maxPlausibleSpeedMps &&
          (mode == TrackingMode.walk || mode == TrackingMode.run)) {
        _gpsState.rejectedPts++;
        DebugLogger.log({
          "event": "gps_reject",
          "reason": "speed_spike",
          "v_imp_mps": vImp,
          "dM": distM,
          "dt_ms": dtMs,
          "rej_pts": _gpsState.rejectedPts,
        });
        return;
      }

      // Debug telemetry (accepted stream)
      _sampleCount++;
      if (dtMs > 3000) {
        _throttledCount++;
        debugPrint('⚠️ GPS THROTTLED ${dtMs}ms (>3s) — accuracy may degrade');
      }

      final n = _sampleCount.toDouble();
      _avgDtMs = ((_avgDtMs * (n - 1)) + dtMs) / n;
      _avgAccuracy = ((_avgAccuracy * (n - 1)) + acc) / n;

      if (_sampleCount % 30 == 0) {
        final pct = (_throttledCount / _sampleCount * 100).toStringAsFixed(1);
        debugPrint(
          '📊 GPS SAMPLE RATE — dt=${_avgDtMs.toStringAsFixed(0)} ms  '
          'acc=${_avgAccuracy.toStringAsFixed(1)} m  '
          'total=$_sampleCount  throttled=$_throttledCount ($pct%)',
        );
      }

      debugPrint(
        'GPS ACCEPT acc=${acc.toStringAsFixed(1)}m dist=${distM.toStringAsFixed(2)}m dt=${dtMs}ms',
      );
    }

    // Accepted point
    _gpsState.acceptedPts++;

    _pointsSaved++;
    if (_pointsSaved % 25 == 0) {
      debugPrint('💾 Trackpoints saved: $_pointsSaved');
    }

    // --- Update state metrics ---
    final newDistanceM = _state.distanceM + distM;
    final newDurationS =
    (liveController?.elapsed.inMilliseconds ?? now.difference(_startTime!).inMilliseconds) / 1000.0;


    final newPolyline = List<LatLng>.from(_state.polyline);
    newPolyline.add(latLng);

    _state = _state.copyWith(
      distanceM: newDistanceM,
      durationS: newDurationS,
      polyline: newPolyline,
    );

    _emit();

    // 🔒 Push truth to controller
    liveController?.setDistanceFromRecorder(newDistanceM);

    // --- Save trackpoint ---
    try {
      await _repo.insertTrackPoint({
        'activity_id': _activityId!,
        'ts': now.millisecondsSinceEpoch,
        'lat': latLng.latitude,
        'lng': latLng.longitude,
        'alt': pos.altitude,
        'accuracy': pos.accuracy,
        'speed': pos.speed,
        'heading': pos.heading,
      });
    } catch (e) {
      debugPrint('Error inserting trackpoint: $e');
    }

    _lastPointTime = now;
    _lastPointPos = latLng;
    _lastAlt = pos.altitude;

    DebugLogger.log({
      "event": "gps_fix",
      "lat": pos.latitude,
      "lng": pos.longitude,
      "acc": acc,
      "acc_gate_m": maxAcc,
      "alt": pos.altitude,
      "dt_ms": dtMs,
      "delta_m": distM,
      "v_imp_mps": vImp,
      "total_m": newDistanceM,
      "accepted_pts": _gpsState.acceptedPts,
      "rejected_pts": _gpsState.rejectedPts,
    });
    unawaited(_persistRecorderSnapshotThrottled());

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
          minTimeMs: 1000,
          minDistM: 2.0,
          maxAccuracyM: 50.0,
        );
      case TrackingMode.run:
        return const _ModeThresholds(
          minTimeMs: 900,
          minDistM: 2.0,
          maxAccuracyM: 30.0,
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

// ----------------------------
// Garmin-parity gate classes
// ----------------------------

class GpsGateConfig {
  /// Reject huge “teleport” spikes for run/walk.
  final double maxPlausibleSpeedMps;

  /// Always reject if accuracy is worse than this.
  final double accuracyHardCapM;

  /// Early window to avoid “start lag” (slightly looser accuracy early).
  final Duration startWindow;

  /// Added to mode.maxAccuracyM during startWindow.
  final double startAccuracyRelaxM;

  const GpsGateConfig({
    this.maxPlausibleSpeedMps = 12.0, // ~26.8 mph
    this.accuracyHardCapM = 120.0,
    this.startWindow = const Duration(seconds: 20),
    this.startAccuracyRelaxM = 25.0,
  });
}

class GpsGateState {
  Position? lastAccepted;
  DateTime? startedAt;
  int acceptedPts = 0;
  int rejectedPts = 0;
  double acceptedMeters = 0.0;

  void reset() {
    lastAccepted = null;
    startedAt = null;
    acceptedPts = 0;
    rejectedPts = 0;
    acceptedMeters = 0.0;
  }
}
