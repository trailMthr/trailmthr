// lib/features/activity/controllers/live_activity_controller.dart
// Central state spine for LIVE activity UX only.
// Owns lifecycle truth, pause/resume, recovery, and guards.
// Does NOT persist completed activities.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tracking_mode.dart';

enum LiveActivityLifecycle {
  idle,
  recording,
  paused,
  finalizing,
  finalized,
}

enum LiveActivitySource {
  recorded,
  resumed,
  importedGpx,
  legacy,
}

enum RecoveryResult {
  none,
  resumable,
  discarded,
}

enum ActivityIntegrity {
  complete,
  incomplete,
  unrecoverable,
}

class LiveActivityController extends ChangeNotifier {
  // ------------------------------------------------------------
  // CORE STATE
  // ------------------------------------------------------------

  LiveActivityLifecycle _lifecycle = LiveActivityLifecycle.idle;
  LiveActivityLifecycle get lifecycle => _lifecycle;

  bool get isLive =>
      _lifecycle == LiveActivityLifecycle.recording ||
      _lifecycle == LiveActivityLifecycle.paused;

  bool get isRecording => _lifecycle == LiveActivityLifecycle.recording;
  bool get isPaused => _lifecycle == LiveActivityLifecycle.paused;

  TrackingMode? selectedMode;
  LiveActivitySource source = LiveActivitySource.recorded;

  // ------------------------------------------------------------
  // TIMEKEEPING (authoritative)
  // ------------------------------------------------------------

  DateTime? _sessionStart;
  DateTime? _pauseStart;
  Duration _pausedTotal = Duration.zero;

  Timer? _ticker;

  Duration get elapsed {
    if (_sessionStart == null) return Duration.zero;

    final now = (isPaused && _pauseStart != null)
        ? _pauseStart!
        : DateTime.now();

    final raw = now.difference(_sessionStart!);
    final effective = raw - _pausedTotal;

    return effective.isNegative ? Duration.zero : effective;
  }

  // ------------------------------------------------------------
  // DISTANCE (owned elsewhere, but guarded here)
  // ------------------------------------------------------------

  double distanceMeters = 0.0;

  void addDistance(double meters) {
    if (!isRecording) return; // 🚫 CRITICAL FIX
    distanceMeters += meters;
    _persistLiveSnapshot();
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
  // INIT / RECOVERY
  // ------------------------------------------------------------

  LiveActivityController() {
    _recoverIfNeeded();
  }
//
double _statsPanelExtent = 0.28;

double get statsPanelExtent => _statsPanelExtent;

set statsPanelExtent(double v) {
  _statsPanelExtent = v.clamp(0.15, 0.9);
  notifyListeners();
}
//
bool _autoPause = true;

bool get autoPause => _autoPause;

set autoPause(bool v) {
  _autoPause = v;
  notifyListeners();
}
//
bool _shareLiveLocation = false;

bool get shareLiveLocation => _shareLiveLocation;

set shareLiveLocation(bool v) {
  _shareLiveLocation = v;
  notifyListeners();
}
//
bool _lapSounds = true;

bool get lapSounds => _lapSounds;

set lapSounds(bool v) {
  _lapSounds = v;
  notifyListeners();
}


  Future<void> _recoverIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    final hasLive = prefs.getBool('has_live_session') ?? false;
    if (!hasLive) return;

    _sessionStart =
        DateTime.fromMillisecondsSinceEpoch(prefs.getInt('live_start')!);
    distanceMeters = prefs.getDouble('live_distance') ?? 0.0;

    final elapsedSeconds = prefs.getInt('live_elapsed') ?? 0;
    _pausedTotal = Duration.zero;
    _pauseStart = null;

    _lifecycle = LiveActivityLifecycle.paused;
    needsResumePrompt = true;
    source = LiveActivitySource.resumed;

    notifyListeners();
  }

  // ------------------------------------------------------------
  // LIFECYCLE CONTROLS
  // ------------------------------------------------------------

  void start(TrackingMode mode) {
    selectedMode = mode;
    source = LiveActivitySource.recorded;

    _sessionStart = DateTime.now();
    _pausedTotal = Duration.zero;
    _pauseStart = null;
    distanceMeters = 0.0;

    _lifecycle = LiveActivityLifecycle.recording;
    _startTicker();
    _persistLiveSnapshot();

    notifyListeners();
  }

  void pause() {
    if (!isRecording) return;

    _pauseStart = DateTime.now();
    _lifecycle = LiveActivityLifecycle.paused;
    _persistLiveSnapshot();

    notifyListeners();
  }

  void resume() {
    if (!isPaused) return;

    if (_pauseStart != null) {
      _pausedTotal += DateTime.now().difference(_pauseStart!);
      _pauseStart = null;
    }

    _lifecycle = LiveActivityLifecycle.recording;
    _persistLiveSnapshot();

    notifyListeners();
  }

  void beginFinalizing() {
    if (!isLive) return;

    _lifecycle = LiveActivityLifecycle.finalizing;
    _stopTicker();

    notifyListeners();
    onFinalizeRequested?.call();
  }

  void markFinalized() {
    // 🛑 STEP 5 GUARD
    if (elapsed.inSeconds <= 0 || distanceMeters <= 0) {
      discardLiveSession();
      return;
    }

    _clearLiveSnapshot();
    _lifecycle = LiveActivityLifecycle.finalized;

    notifyListeners();
    onFinalized?.call();
  }

//
void forceIdle() {
  _lifecycle = LiveActivityLifecycle.idle;
  notifyListeners();
}

  void discardLiveSession() {
    _clearLiveSnapshot();
    _resetInternal();
    notifyListeners();
  }

  void reset() {
    _resetInternal();
    notifyListeners();
  }

  // ------------------------------------------------------------
  // INTERNAL HELPERS
  // ------------------------------------------------------------

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isRecording) notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _resetInternal() {
    _stopTicker();
    _lifecycle = LiveActivityLifecycle.idle;
    selectedMode = null;
    source = LiveActivitySource.recorded;
    _sessionStart = null;
    _pauseStart = null;
    _pausedTotal = Duration.zero;
    distanceMeters = 0.0;
    needsResumePrompt = false;
  }

  // ------------------------------------------------------------
  // SNAPSHOT PERSISTENCE (Issue B core)
  // ------------------------------------------------------------

  Future<void> _persistLiveSnapshot() async {
    if (!isLive) return;

    final prefs = await SharedPreferences.getInstance();

    prefs.setBool('has_live_session', true);
    prefs.setInt('live_start', _sessionStart!.millisecondsSinceEpoch);
    prefs.setInt('live_elapsed', elapsed.inSeconds);
    prefs.setDouble('live_distance', distanceMeters);
    prefs.setString('live_lifecycle', _lifecycle.name);
  }

  Future<void> _clearLiveSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('has_live_session');
    prefs.remove('live_start');
    prefs.remove('live_elapsed');
    prefs.remove('live_distance');
    prefs.remove('live_lifecycle');
  }
}
