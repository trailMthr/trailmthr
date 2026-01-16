// lib/features/activity/controllers/live_activity_controller.dart
// Central state spine for LIVE activity UX only.
// Owns lifecycle truth, pause/resume, recovery, and guards.
// Does NOT persist completed activities.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tracking_mode.dart';
import 'package:flutter/widgets.dart';

import 'package:geolocator/geolocator.dart';

enum LiveActivityLifecycle {
  idle,
  recording,
  paused,
  completed, // reserved (not used yet)
  finalizing,
  finalized,
}

enum LiveActivitySource {
  recorded,
  resumed,
  importedGpx,
  legacy,
}

class LiveActivityController extends ChangeNotifier 
  with WidgetsBindingObserver {
  // ------------------------------------------------------------
  // CORE STATE
  // ------------------------------------------------------------
//
bool _recoveryComplete = false;
bool get recoveryComplete => _recoveryComplete;

  LiveActivityLifecycle _lifecycle = LiveActivityLifecycle.idle;
  LiveActivityLifecycle get lifecycle => _lifecycle;

  bool get isLive =>
      _lifecycle == LiveActivityLifecycle.recording ||
      _lifecycle == LiveActivityLifecycle.paused;

  bool get isRecording => _lifecycle == LiveActivityLifecycle.recording;
  bool get isPaused => _lifecycle == LiveActivityLifecycle.paused;

  TrackingMode? selectedMode;
  String? activityId;

  LiveActivitySource source = LiveActivitySource.recorded;

  // ------------------------------------------------------------
  // TIMEKEEPING (authoritative)
  // ------------------------------------------------------------

  DateTime? _sessionStart;
  DateTime? _pauseStart;
  Duration _pausedTotal = Duration.zero;

  Timer? _ticker;

//
DateTime? get sessionStart => _sessionStart;

//
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

    // (Later we can add battery / “unrestricted” checks here too.)

    return true;
  }


  Duration get elapsed {
    if (_sessionStart == null) return Duration.zero;

    final now = (isPaused && _pauseStart != null) ? _pauseStart! : DateTime.now();
    final raw = now.difference(_sessionStart!);
    final effective = raw - _pausedTotal;

    return effective.isNegative ? Duration.zero : effective;
  }

  // ------------------------------------------------------------
  // DISTANCE (owned elsewhere, but guarded here)
  // ------------------------------------------------------------

  double distanceMeters = 0.0;

  DateTime? _lastPersistAt;

  Future<void> _persistLiveSnapshotThrottled() async {
    final now = DateTime.now();
    if (_lastPersistAt != null &&
        now.difference(_lastPersistAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastPersistAt = now;
    await _persistLiveSnapshot();
  }

void setDistanceFromRecorder(double meters) {
  if (!isLive) return; // allow updates while paused/recovery UI is visible
  distanceMeters = meters;
  unawaited(_persistLiveSnapshotThrottled());
  notifyListeners();
}


  // ------------------------------------------------------------
  // UI FLAGS
  // ------------------------------------------------------------

  bool needsResumePrompt = false;

  // ------------------------------------------------------------
  // HOOKS
  // ------------------------------------------------------------

  VoidCallback? onFinalizeRequested;
  VoidCallback? onFinalized;

  // ------------------------------------------------------------
  // USER SETTINGS / UI KNOBS
  // ------------------------------------------------------------

  double _statsPanelExtent = 0.28;
  double get statsPanelExtent => _statsPanelExtent;
  set statsPanelExtent(double v) {
    _statsPanelExtent = v.clamp(0.15, 0.9);
    notifyListeners();
  }

  bool _autoPause = true;
  bool get autoPause => _autoPause;
  set autoPause(bool v) {
    _autoPause = v;
    notifyListeners();
  }

  bool _shareLiveLocation = false;
  bool get shareLiveLocation => _shareLiveLocation;
  set shareLiveLocation(bool v) {
    _shareLiveLocation = v;
    notifyListeners();
  }

  bool _lapSounds = true;
  bool get lapSounds => _lapSounds;
  set lapSounds(bool v) {
    _lapSounds = v;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // INIT / RECOVERY
  // ------------------------------------------------------------

  LiveActivityController() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initRecovery() async {
    await _recoverIfNeeded();
    _recoveryComplete = true;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // LIFECYCLE GUARDS
  // ------------------------------------------------------------

  bool _canTransition(LiveActivityLifecycle from, LiveActivityLifecycle to) {
    const allowed = {
      LiveActivityLifecycle.idle: {LiveActivityLifecycle.recording},
      LiveActivityLifecycle.recording: {
        LiveActivityLifecycle.paused,
        LiveActivityLifecycle.finalizing
      },
      LiveActivityLifecycle.paused: {
        LiveActivityLifecycle.recording,
        LiveActivityLifecycle.finalizing
      },
      LiveActivityLifecycle.finalizing: {LiveActivityLifecycle.finalized},
      LiveActivityLifecycle.finalized: {LiveActivityLifecycle.idle},
    };
    return allowed[from]?.contains(to) ?? false;
  }

  void _setLifecycle(LiveActivityLifecycle next) {
    if (!_canTransition(_lifecycle, next)) {
      // In debug, scream. In release, ignore but never lie.
      assert(false, 'Illegal lifecycle transition: $_lifecycle -> $next');
      return;
    }
    _lifecycle = next;
  }

  /// Internal hard reset that may bypass guardrails (used for discard/recovery safety)
  void _hardSetIdle() {
    _lifecycle = LiveActivityLifecycle.idle;
  }

  // ------------------------------------------------------------
  // PUBLIC CONTROLS
  // ------------------------------------------------------------

  Future<void> start(TrackingMode mode) async {
    if (_lifecycle != LiveActivityLifecycle.idle) {
      assert(false, 'start() called when not idle: $_lifecycle');
      return;
    }
activityId = DateTime.now().millisecondsSinceEpoch.toString();
    selectedMode = mode;
    source = LiveActivitySource.recorded;

    _sessionStart = DateTime.now();
    _pauseStart = null;
    _pausedTotal = Duration.zero;
    distanceMeters = 0.0;
    needsResumePrompt = false;

    _setLifecycle(LiveActivityLifecycle.recording);
    _startTicker();

    await _persistLiveSnapshot();
    notifyListeners();
  }

  Future<void> pause() async{
    if (_lifecycle != LiveActivityLifecycle.recording) return;


    _pauseStart = DateTime.now();
    _setLifecycle(LiveActivityLifecycle.paused);

    await _persistLiveSnapshot();
    notifyListeners();
  }

  Future<void> resume() async{
    if (_lifecycle != LiveActivityLifecycle.paused) return;

    if (_pauseStart != null) {
      _pausedTotal += DateTime.now().difference(_pauseStart!);
    }
    _pauseStart = null;

    _setLifecycle(LiveActivityLifecycle.recording);

    _startTicker();

    await _persistLiveSnapshot();
    notifyListeners();
  }

  Future<void> beginFinalizing() async {
    if (!isLive) return;

    _setLifecycle(LiveActivityLifecycle.finalizing);
    _stopTicker();

    // Snapshot one last time so recovery doesn't lie about state
    await _persistLiveSnapshot();

    notifyListeners();
    onFinalizeRequested?.call();
  }

  void markFinalized() {
    if (_lifecycle != LiveActivityLifecycle.finalizing) return;

    // Integrity gate: if nothing meaningful was recorded, discard.
    if (elapsed.inSeconds <= 0 || distanceMeters <= 0) {
      unawaited(discardLiveSession());
      return;
    }

    unawaited(_clearLiveSnapshot());

    _setLifecycle(LiveActivityLifecycle.finalized);

    notifyListeners();
    onFinalized?.call();
  }

  /// Discard current live session and clear snapshot (abort / invalid finalize)
Future<void> discardLiveSession() async {
  await _clearLiveSnapshot();
  _stopTicker();
  _resetInternal();
  notifyListeners();
}


  /// Force controller into idle state (hard recovery / UI safety)
Future<void> forceIdle() async {
  await _clearLiveSnapshot();
  _stopTicker();
  _resetInternal();
  notifyListeners();
}


  /// Full reset after completion or abort (alias of forceIdle)
  Future<void> reset() async {
    await forceIdle();
  }

  /// Dev helper: allow UI to return to idle only from finalized
  void devForceIdleFromFinalized() {
    if (_lifecycle != LiveActivityLifecycle.finalized) return;
    _setLifecycle(LiveActivityLifecycle.idle);
    notifyListeners();
  }

  // ------------------------------------------------------------
  // TICKER (UI refresh)
  // ------------------------------------------------------------

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      // Only tick UI while actively recording
      if (isLive) notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ------------------------------------------------------------
  // INTERNAL RESET
  // ------------------------------------------------------------

  void _resetInternal() {
    _stopTicker();
    _hardSetIdle(); // bypass guardrails intentionally (internal only)

    selectedMode = null;

    source = LiveActivitySource.recorded;

    _sessionStart = null;
    _pauseStart = null;
    _pausedTotal = Duration.zero;

    distanceMeters = 0.0;
    needsResumePrompt = false;

    _lastPersistAt = null;
  }

  // ------------------------------------------------------------
  // SNAPSHOT PERSISTENCE
  // ------------------------------------------------------------

  static const _kHasLive = 'has_live_session';
  static const _kLiveStart = 'live_start';
  static const _kLiveElapsed = 'live_elapsed';
  static const _kLiveDistance = 'live_distance';
  static const _kLiveLifecycle = 'live_lifecycle';
//
static const _kLiveActivityId = 'live_activity_id';
static const _kLiveMode = 'live_mode';

  Future<void> _persistLiveSnapshot() async {
    if (!isLive) return;
    if (_sessionStart == null) return;
    if (activityId == null || activityId!.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLiveActivityId, activityId ?? '');
    await prefs.setString(_kLiveMode, selectedMode?.name ?? '');

    await prefs.setBool(_kHasLive, true);
    await prefs.setInt(_kLiveStart, _sessionStart!.millisecondsSinceEpoch);
    await prefs.setInt(_kLiveElapsed, elapsed.inSeconds);
    await prefs.setDouble(_kLiveDistance, distanceMeters);
    await prefs.setString(_kLiveLifecycle, _lifecycle.name);
  }

  Future<void> _clearLiveSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLiveActivityId);
    await prefs.remove(_kLiveMode);

    await prefs.remove(_kHasLive);
    await prefs.remove(_kLiveStart);
    await prefs.remove(_kLiveElapsed);
    await prefs.remove(_kLiveDistance);
    await prefs.remove(_kLiveLifecycle);
  }

  Future<void> _recoverIfNeeded() async {
    
    final prefs = await SharedPreferences.getInstance();

    final hasLive = prefs.getBool(_kHasLive) ?? false;
    if (!hasLive) return;

    final startMs = prefs.getInt(_kLiveStart);
    if (startMs == null) {
      // corrupted snapshot -> clear and bail safely
      await _clearLiveSnapshot();
      return;
    }
final savedId = prefs.getString(_kLiveActivityId);
activityId = (savedId != null && savedId.isNotEmpty) ? savedId : null;

final savedMode = prefs.getString(_kLiveMode);
if (savedMode != null) {
  selectedMode = TrackingMode.values.firstWhere(
    (m) => m.name == savedMode,
    orElse: () => TrackingMode.walk,
  );
}

    _sessionStart = DateTime.fromMillisecondsSinceEpoch(startMs);
    distanceMeters = prefs.getDouble(_kLiveDistance) ?? 0.0;

    final elapsedSeconds = prefs.getInt(_kLiveElapsed) ?? 0;
    final savedElapsed = Duration(seconds: elapsedSeconds);

    // Reconstruct pausedTotal so that elapsed == savedElapsed while paused.
    final raw = DateTime.now().difference(_sessionStart!);
    _pausedTotal = raw - savedElapsed;
    if (_pausedTotal.isNegative) _pausedTotal = Duration.zero;

    // Put controller into PAUSED so we never "lie" by auto-recording.
    _pauseStart = DateTime.now();
    _lifecycle = LiveActivityLifecycle.paused;

    needsResumePrompt = true;
    source = LiveActivitySource.resumed;
_startTicker(); // ensure UI refresh after app restart recovery

    notifyListeners();
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive) {
    if (isLive) {
      unawaited(_persistLiveSnapshot()); // best-effort snapshot; do not block lifecycle

    }
  }
}

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    super.dispose();
  }
}
