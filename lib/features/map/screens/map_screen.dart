// lib/features/map/screens/map_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/saved_place_db.dart';
import '../widgets/trailmthr_flower.dart';

import '../../map/screens/marker_hub_screen.dart';
import '../screens/marker_details_screen.dart';
import 'marker_creator_screen.dart';

import '../../trekmaster/screens/trekmaster_home_screen.dart';

import '../../activity/data/activity_repository.dart';
import '../../activity/controllers/activity_recorder.dart';
import '../../activity/controllers/live_activity_controller.dart';
import '../../activity/models/tracking_mode.dart';
import '../../activity/screens/activity_history_screen.dart';
import '../../activity/screens/activity_summary_screen.dart';
import '../../activity/widgets/live_stats_panel.dart';
import '../../activity/widgets/start_activity_sheet.dart';

import 'package:trailmthr_test2/features/thinkspace/data/thinkspace_repository.dart';
import 'package:trailmthr_test2/features/thinkspace/screens/thinkspace_home_screen.dart';
import 'package:trailmthr_test2/features/thinkspace/widgets/quicknote_sheet.dart';

import 'package:trailmthr_test2/features/activity/data/activity_db.dart';
import 'package:trailmthr_test2/core/debug_export.dart';

// ------------------------------------------------------------
// OWNER / DEVICE ID (for markers, notes, etc.)
// ------------------------------------------------------------
Future<String> getDeviceOwnerId() async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString("owner_id");

  if (id == null) {
    id = const Uuid().v4();
    await prefs.setString("owner_id", id);
  }

  return id;
}

class MapScreen extends StatefulWidget {
  final LiveActivityController controller;
  final ActivityRecorder recorder;
  final ThinkSpaceRepository thinkRepo;

  MapScreen({
    super.key,
    required this.controller,
    required this.recorder,
    required this.thinkRepo,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // ------------------------------------------------------------
  // FLOWER MENU CONTROLLERS
  // ------------------------------------------------------------
  late AnimationController _menuController;
  late Animation<double> _menuAnim;

  // ------------------------------------------------------------
  // SEED BUTTON SCREEN POSITION
  // ------------------------------------------------------------
  Offset _seedCenter = Offset.zero;

  // ------------------------------------------------------------
  // MAP + GPS STATE
  // ------------------------------------------------------------
  final MapController _mapController = MapController();

  ll.LatLng _mapCenter = const ll.LatLng(34.0, -118.0);
  double _mapZoom = 13.0;

  ll.LatLng? currentLocation;
  StreamSubscription<Position>? _gpsSub;

  bool _hasCenteredOnce = false;
  bool _mapReady = false;

  late ThinkSpaceRepository _thinkRepo;

  // ------------------------------------------------------------
  // SAVED PLACES (MARKERS, WHISPERS, ETC.)
  // ------------------------------------------------------------
  List<Map<String, dynamic>> savedPlaces = [];

  // ------------------------------------------------------------
  // TrailMthr Core Colors (Phase 3 Locked)
  // ------------------------------------------------------------
  final Color _earthDark = const Color(0xFF1E1B18);
  final Color _earthMedium = const Color(0xFF3C342B);
  final Color _earthLight = const Color(0xFFDAC7A1);
  final Color _accentMushroom = const Color(0xFF9C6B4F);

 // ------------------------------------------------------------
// ACTIVITY RECORDER + CONTROLLER
// ------------------------------------------------------------
late final LiveActivityController _activityController;
late final ActivityRecorder _recorder;

RecorderState _state = RecorderState.initial();
late RecorderState _recorderState;

StreamSubscription<RecorderState>? _recorderSub;

bool _resumeDialogShown = false;

ActivityRecorder get recorder => _recorder;
LiveActivityController get controller => _activityController;

///// To prevent multiple resume prompts
bool _resumePromptInFlight = false;

// ------------------------------------------------------------
// LIFECYCLE
// ------------------------------------------------------------
late final VoidCallback _resumeListener;

@override
void initState() {
  super.initState();

  // 1) Assign injected dependencies FIRST
  _recorder = widget.recorder;
  _activityController = widget.controller;
  _thinkRepo = widget.thinkRepo;

  // 2) Wire recorder -> controller (so UI distance updates always work)
  _recorder.liveController = _activityController;
//
unawaited(_activityController.initRecovery().then((_) => _maybePromptResume()));
  // 3) Listener (store the callback so removeListener works)

  // 4) Safe time to show dialogs (one-shot)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _maybePromptResume();
  });

  // 5) Recorder UI state init
  _recorderState = RecorderState.initial();
  _state = RecorderState.initial();

  // 6) Subscribe once to recorder state
  _recorderSub = _recorder.stateStream.listen((s) {
    if (!mounted) return;

    setState(() {
      _recorderState = s;
      _state = s;
    });

    // Auto-follow while recording
    if (s.isRecording && s.polyline.isNotEmpty) {
      final last = s.polyline.last;
      _mapController.move(last, _mapZoom);
    }
  });

  // 7) Your other init work
  _menuController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  _menuAnim = CurvedAnimation(
    parent: _menuController,
    curve: Curves.easeOutBack,
  );

  _loadSavedPlaces();
  _initLocation();
}

Future<void> _maybePromptResume() async {
  if (!mounted) return;

  final c = _activityController;

  // Wait for recovery to finish
  if (!c.recoveryComplete) return;

  // Prevent concurrent prompts during async DB checks
  if (_resumePromptInFlight) return;
  _resumePromptInFlight = true;

  try {
    if (_resumeDialogShown) return;
    if (!c.needsResumePrompt) return;

    final id = c.activityId;
    if (id == null || id.isEmpty) {
      c.needsResumePrompt = false;
      return;
    }

    final ok = await _recorder.hasUnfinishedActivityInDb(id);
    if (!ok) {
      c.needsResumePrompt = false;
      await c.forceIdle();
      await _recorder.discardSession();
      return;
    }

    // Disarm prompt BEFORE showing dialog
    _resumeDialogShown = true;
    c.needsResumePrompt = false;

    _showResumeDialog();
  } finally {
    _resumePromptInFlight = false;
  }
}


@override
void dispose() {
  _gpsSub?.cancel();
  _recorderSub?.cancel();

  _menuController.dispose();
  super.dispose();
}

void _showResumeDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Unfinished activity'),
      content: const Text(
        'You have an activity that did not finish. What would you like to do?',
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _activityController!.discardLiveSession();
            await _recorder.discardSession();
          },
          child: const Text('Discard'),
        ),
        ElevatedButton(
onPressed: () async {
  Navigator.of(context).pop();

  final c = _activityController!;
  _recorder.liveController = c;

  // Keep controller paused->recording (ticker resumes)
  await c.resume();

  // Resume recorder stream + attach to existing activity
  await _recorder.resumeFromRecovery(
    mode: c.selectedMode ?? TrackingMode.walk,
    activityId: c.activityId!,
    startTime: c.sessionStart!,
    distanceM: c.distanceMeters,
    createIfMissing: false, // you already validated ok==true earlier
  );
},

          child: const Text('Resume'),
        ),
      ],
    ),
  );
}

  // ------------------------------------------------------------
  // SAFE SETSTATE
  // ------------------------------------------------------------
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ------------------------------------------------------------
  // THINKSPACE NAV
  // ------------------------------------------------------------
  void _openThinkSpace() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThinkSpaceHomeScreen(repository: _thinkRepo),
      ),
    );
  }

  void _openIdeasQuickNote() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: QuickNoteSheet(
            repository: _thinkRepo,
            locationId: null,
            activityId: null,
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // MARKER STYLE HELPERS
  // ------------------------------------------------------------
  IconData markerTypeIcon(String type) {
    switch (type) {
      case "camp":
        return Icons.local_fire_department;
      case "water":
        return Icons.water_drop;
      case "view":
        return Icons.visibility;
      case "hazard":
        return Icons.warning;
      case "whisper":
        return Icons.forum;
      case "poi":
        return Icons.star;
      default:
        return Icons.place;
    }
  }

  Color markerTypeColor(String type) {
    switch (type) {
      case "camp":
        return Colors.green;
      case "water":
        return Colors.blue;
      case "view":
        return Colors.purple;
      case "hazard":
        return Colors.red;
      case "whisper":
        return Colors.teal;
      case "poi":
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // ------------------------------------------------------------
  // MAP CAMERA SAFETY WRAPPER
  // ------------------------------------------------------------
  void _safeMove(ll.LatLng pos, double zoom) {
    if (!_mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_mapReady) return;
        try {
          _mapController.move(pos, zoom);
        } catch (_) {}
      });
      return;
    }

    try {
      _mapController.move(pos, zoom);
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // ROUTE PLANNER + HISTORY
  // ------------------------------------------------------------
  void _openRoutePlanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Route planner coming soon")),
    );
  }

  void _openHistoryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ActivityHistoryScreen(),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOCATION / GPS SETUP
  // ------------------------------------------------------------
  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final initial = ll.LatLng(pos.latitude, pos.longitude);

      safeSetState(() {
        currentLocation = initial;
        _mapCenter = initial;
        _mapZoom = 15;
      });

      if (_mapReady && !_hasCenteredOnce) {
        _hasCenteredOnce = true;
        _safeMove(initial, 16);
      }


    } catch (e) {
      debugPrint("[GPS] ERROR: $e");
    }
  }

  // ------------------------------------------------------------
  // SQLITE LOAD + REFRESH
  // ------------------------------------------------------------
  Future<void> _loadSavedPlaces() async {
    final places = await SavedPlaceDb.instance.getAllPlaces();
    setState(() => savedPlaces = places);
  }

  Future<void> _reloadSavedPlaces() async {
    final places = await SavedPlaceDb.instance.getAllPlaces();
    setState(() {
      savedPlaces
        ..clear()
        ..addAll(places);
    });
  }
//
Future<void> _finishActivity() async {
await _recorder.finish();

}
//
Future<void> _confirmStop() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('End Activity?'),
      content: const Text('This will finish and save your activity.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Finish'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // Use the same stop pipeline as the Stop button.
  await _openActivityFolder();
}



  // ------------------------------------------------------------
  // MARKER DETAIL FLOW
  // ------------------------------------------------------------
  Future<void> _openPinDetails(Map<String, dynamic> place) async {
    final myId = await getDeviceOwnerId();

    final normalized = {
      ...place,
      "owner_id": place["owner_id"] ?? myId,
      "visibility": place["visibility"] ?? "private",
      "locked": place["locked"] ?? 0,
      "notes": place["notes"] ?? "",
      "type": place["type"] ?? "poi",
      "name": place["name"] ?? "Unnamed",
    };

    final isOwner = normalized["owner_id"] == myId;
    final isLocked = normalized["locked"] == 1;

    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MarkerDetailsScreen(
          marker: normalized,
          canEdit: isOwner && !isLocked,
        ),
      ),
    );

    if (updated != null) {
      await SavedPlaceDb.instance.upsertPlace(updated);
      await _loadSavedPlaces();
    }
  }

  // ------------------------------------------------------------
  // MAP WIDGET
  // ------------------------------------------------------------
  Widget _buildMap(ll.LatLng center) {
    final ll.LatLng? liveDot =
    _recorderState.polyline.isNotEmpty ? _recorderState.polyline.last : currentLocation;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _mapZoom,
        onMapReady: () {
          _mapReady = true;

          if (currentLocation != null && !_hasCenteredOnce) {
            _hasCenteredOnce = true;
            _safeMove(currentLocation!, 16);
          }
        },
        onPositionChanged: (pos, hasGesture) {
          if (!mounted) return;
          if (pos.center != null) _mapCenter = pos.center!;
          if (pos.zoom != null) _mapZoom = pos.zoom!;
        },
        onLongPress: (tapPos, tappedPoint) async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => MarkerCreatorScreen(
              position: tappedPoint,
              thinkRepo: _thinkRepo,
          ),
          );
          // Marker creator saves directly into DB. Refresh list after close.
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) _reloadSavedPlaces();
  
});

        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.trailmthr.app',
        ),
    // 🔶 LIVE ACTIVITY POLYLINE
    if (_recorderState.polyline.isNotEmpty)
      PolylineLayer(
        polylines: [
          Polyline(
            points: _recorderState.polyline,
            strokeWidth: 4,
            color: Colors.orangeAccent, // or whichever
          ),
        ],
      ),
        // Saved markers
        MarkerLayer(
          markers: [
            for (final p in savedPlaces)
              Marker(
                point: ll.LatLng(
                  (p["lat"] as num).toDouble(),
                  (p["lng"] as num).toDouble(),
                ),
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () => _openPinDetails(p),
                  child: Icon(
                    markerTypeIcon((p["type"] ?? "poi").toString()),
                    size: 34,
                    color: markerTypeColor((p["type"] ?? "poi").toString()),
                  ),
                ),
              ),

// Current location indicator (follow live polyline when recording)
if (liveDot != null)
  Marker(
    point: liveDot,
    width: 30,
    height: 30,
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(0.85),
        border: Border.all(color: Colors.white, width: 2),
      ),
    ),
  ),

          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TOP-RIGHT BUTTONS
  // ------------------------------------------------------------
  Widget _buildTopButtons() {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _roundButton(
            icon: Icons.my_location_rounded,
            onTap: () {
              if (currentLocation != null) {
                _safeMove(currentLocation!, 16);
              }
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _earthDark.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: _earthLight),
      ),
    );
  }

  // ------------------------------------------------------------
  // FLOWER PETAL CALLBACKS
  // ------------------------------------------------------------
  void _openMarkersMenu() {
    if (!_menuController.isDismissed) {
      _menuController.reverse();
    }

    Future.delayed(const Duration(milliseconds: 160), () async {
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarkerHubScreen(mapCenter: _mapCenter),
        ),
      );

      if (!mounted) return;
      await _reloadSavedPlaces();
    });
  }

  void _openTrekMaster() {
    if (!_menuController.isDismissed) {
      _menuController.reverse();
    }

    Future.delayed(const Duration(milliseconds: 160), () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TrekMasterHomeScreen(),
        ),
      );
    });
  }

Future<void> _openActivityFolder() async {
  if (!_state.isRecording) return;

  // Finish recording & persist to DB
  final finished = await _recorder.finishAndSave();
  if (!mounted || finished == null) return;

  // 🚨 finished IS the activity map — use it directly
  final bool? saved = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => ActivitySummaryScreen(
        activityId: finished['id'],
        activity: finished,
        thinkRepo: _thinkRepo,
      ),
    ),
  );

  if (saved == true) {
    _activityController!.beginFinalizing();
    _activityController!.reset();
  }
}


  void _openStartActivitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StartActivitySheet(
          controller: _activityController!,
          onAddRoute: _openRoutePlanner,
onStart: (mode) async {
  // 1) Start controller FIRST and await it (controller generates activityId + sessionStart)
  await _activityController.start(mode);

  // 2) Wire recorder -> controller
  _recorder.liveController = _activityController;

  // 3) Start recorder using controller's ID + start time (single source of truth)
  await _recorder.start(
    mode: mode,
    activityIdOverride: _activityController.activityId,
    startTimeOverride: _activityController.sessionStart,
    distanceOverride: _activityController.distanceMeters,
    createIfMissing: true,
  );
},


          onOpenHistory: _openHistoryScreen,
        );
      },
    );
  }

  // ------------------------------------------------------------
  // ROOT BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isRecording = false;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (_activityController!.isLive) {
          await _confirmStop();
          return;
        }
        Navigator.of(context).maybePop();
      },
      child: Scaffold(
appBar: AppBar(
  title: const Text("TrailMthr"),
  actions: [
    PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == "export_logs") {
          final path = await DebugExport.exportLogs();

          final msg = (path == null)
              ? "No logs found"
              : "Logs exported to:\n$path";

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: "export_logs",
          child: Text("Export Debug Logs"),
        ),
      ],
    ),
  ],
),

      body: Stack(
        children: [
          Positioned.fill(child: _buildMap(_mapCenter)),

          TrailMthrFlower(
            onStartActivity: _openStartActivitySheet,
            onOpenMarkers: _openMarkersMenu,
            onOpenIdeas: _openIdeasQuickNote,
            onOpenTrekMaster: _openTrekMaster,
            isRecording: _state.isRecording,
            onOpenActivityHistory: _openHistoryScreen,
          ),

          if (_activityController!.isLive && recorder.hasActiveStream)
            LiveStatsPanel(
              controller: _activityController!,
              recorder: _recorder,
              onStop: _openActivityFolder,
            ),

          _buildTopButtons(),
        ],
      ),
      ),
    );
  }
}
