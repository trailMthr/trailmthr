import 'package:flutter/material.dart';

import 'features/activity/controllers/live_activity_controller.dart';
import 'features/activity/controllers/activity_recorder.dart';
import 'features/activity/data/activity_repository.dart';
import 'features/activity/data/activity_db.dart';

import 'features/thinkspace/data/thinkspace_repository.dart';

import 'features/map/screens/map_screen.dart';
import 'features/thinkspace/screens/thinkspace_home_screen.dart';
import 'features/community/community_placeholder.dart';

import 'package:trailmthr_test2/services/data_export_service.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _index = 1;

  late final ActivityRepository _activityRepo;
  late final ThinkSpaceRepository _thinkRepo;
  late final ActivityRecorder _recorder;
  late final LiveActivityController _activityController;

  @override
  void initState() {
    super.initState();

    _activityRepo = ActivityRepository();
    _thinkRepo = ThinkSpaceRepository(() async => await ActivityDb.instance.database);
    _recorder = ActivityRecorder(_activityRepo, _thinkRepo);

    _activityController = LiveActivityController();

    // Recovery init happens once for app lifetime.
    // MapScreen owns the resume prompt UI.
    _activityController.initRecovery();
  }

  Future<void> _exportAllData() async {
    try {
      final db = await ActivityDb.instance.database;
      final file = await DataExportService.exportFullDatabase(db);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported data to:\n${file.path}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CommunityPlaceholderScreen(),
      MapScreen(
        controller: _activityController,
        recorder: _recorder,
        thinkRepo: _thinkRepo,
      ),
      ThinkSpaceHomeScreen(repository: _thinkRepo),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrailMTHR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export All Data',
            onPressed: _exportAllData,
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Think',
          ),
        ],
      ),
    );
  }
}
