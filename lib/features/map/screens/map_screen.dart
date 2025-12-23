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

import '../../activity/services/activity_recovery_service.dart';

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
  StreamSubscription<RecorderState>? _recorderSub;
  TrackingMode _selectedMode = TrackingMode.walk;
//
late final ActivityRecoveryService _recovery;
ActivityRecorder get recorder => _recorder;
LiveActivityController get controller => _activityController;

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------
@override
void initState() {
  super.initState();

  // 1️⃣ Assign injected dependencies FIRST
  _recorder = widget.recorder;
  _activityController = widget.controller;
  _thinkRepo = widget.thinkRepo;

  // 2️⃣ Now it is SAFE to construct recovery service
  _recovery = ActivityRecoveryService(
    controller: _activityController,
    recorder: _recorder,
  );

  _recovery.recoverIfNeeded();

  // 3️⃣ Flower animation
  _menuController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  _menuAnim = CurvedAnimation(
    parent: _menuController,
    curve: Curves.easeOutBack,
  );

  // 4️⃣ Recorder stream
  _recorderSub = _recorder.stateStream.listen((s) {
    safeSetState(() => _state = s);
  });

  // 5️⃣ Resume prompt
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_activityController.needsResumePrompt) {
      _showResumeDialog();
    }
  });

  // 6️⃣ Data + GPS
  _loadSavedPlaces();
  _initLocation();
}

//


  @override
  void dispose() {
    _gpsSub?.cancel();
    _recorderSub?.cancel();

    _menuController.dispose();
    super.dispose();
  }

//
void recoverSessionIfNeeded() {
  if (!recorder.canResumeSafely) {
    controller.forceIdle();
    recorder.discardSession();
    return;
  }

  recorder.restartGpsStream();
}

//
void _showResumeDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // user must choose
    builder: (_) => AlertDialog(
      title: const Text('Unfinished activity'),
      content: const Text(
        'You have an activity that did not finish. What would you like to do?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _recovery.discard();
          },
          child: const Text('Discard'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _recovery.resume();
            _recorder.restartGpsStream();
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

      _gpsSub?.cancel();
      _gpsSub = Geolocator.getPositionStream().listen((pos) {
        final live = ll.LatLng(pos.latitude, pos.longitude);
        currentLocation = live;

        if (_menuController.isDismissed && mounted) {
          setState(() {});
        }
      });
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
      content: const Text(
        'This will finish and save your activity.',
      ),
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

  // 🔴 lifecycle-controlled stop
  _activityController.beginFinalizing();

  // persist + navigate (this should already exist in MapScreen)
  await _confirmStop();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _activityController.markFinalized();
    _activityController.reset();
  });
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

            // Current location indicator
            if (currentLocation != null)
              Marker(
                point: currentLocation!,
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

    final finished = await _recorder.finishAndSave();
    if (!mounted || finished == null) return;

    final bool? saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivitySummaryScreen(
          activity: finished,
          thinkRepo: _thinkRepo,
          ),
      ),
    );

    if (saved == true) {
      _activityController.beginFinalizing();
_activityController.reset();
    }
  }

  void _openStartActivitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StartActivitySheet(
          controller: _activityController,
          onAddRoute: _openRoutePlanner,
          onStart: (mode) {
            _activityController.start(mode);
            _recorder.start(mode: mode);
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (_activityController.isLive) {
          await _confirmStop();
          return;
        }
        Navigator.of(context).maybePop();
      },
      child: Scaffold(
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

          if (_activityController.isLive && recorder.hasActiveStream)
            LiveStatsPanel(
              controller: _activityController,
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
