import 'package:flutter/material.dart';

import 'features/thinkspace/screens/thinkspace_home_screen.dart';
import 'features/map/screens/map_screen.dart';
import 'features/community/community_placeholder.dart';
import 'features/thinkspace/data/thinkspace_repository.dart';
import 'features/activity/data/activity_db.dart';

import 'features/activity/controllers/activity_recorder_controller.dart';

import 'features/activity/controllers/live_activity_controller.dart';
import 'features/activity/controllers/activity_recorder.dart';

import 'features/activity/data/activity_repository.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  /// MAP always starts centered
  int _index = 1;

  /// For double-back-to-exit behavior
  DateTime? _lastBackPress;

late final ActivityRepository _activityRepo;


  late LiveActivityController _activityController;
  late ActivityRecorder _recorder;
  late final ThinkSpaceRepository _thinkRepo;

  @override
  void initState() {
    super.initState();
_activityRepo = ActivityRepository();
  _activityController = LiveActivityController();

    // One unified DB → ThinkSpace lives in activity DB
    _thinkRepo = ThinkSpaceRepository(() async {
      return ActivityDb.instance.database;
    });

  _thinkRepo.ensureTable();

  _recorder = ActivityRecorder(
    _activityRepo,
    _thinkRepo,
  );
  }

  /// Global back-button handler
  Future<bool> _handleBack() async {
    final now = DateTime.now();

    // 🔴 TODO: wire this to real activity recording state
    final bool isRecordingActive = 
        ActivityRecorderController.instance.isRecording;

    if (isRecordingActive) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Activity in progress"),
          content: const Text(
            "You are currently recording an activity.\n\n"
            "Leaving will stop and discard it.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Leave"),
            ),
          ],
        ),
      );

      return shouldExit ?? false;
    }

    // 🟡 Double-back to exit
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Press back again to exit")),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Screens in stable order: ThinkSpace, Map, Community
    final screens = [
      ThinkSpaceHomeScreen(repository: _thinkRepo),
      MapScreen(
        controller: _activityController,
        recorder: _recorder,
        thinkRepo: _thinkRepo,
      ),
      CommunityPlaceholderScreen(),
    ];

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        body: screens[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'ThinkSpace',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: 'Community',
            ),
          ],
        ),
      ),
    );
  }
}
