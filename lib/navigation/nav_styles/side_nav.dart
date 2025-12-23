import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_state.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/history/trail_history_screen.dart';
import '../../features/import/import_screen.dart';
import '../../features/settings/settings_screen.dart';

class SideNavScaffold extends StatelessWidget {
  const SideNavScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final idx = context.watch<AppState>().currentIndex;

    final pages = const [
      MapScreen(),
      TrailHistoryScreen(),
      ImportScreen(),
      SettingsScreen(),
    ];

    void goTo(int i) {
      context.read<AppState>().setIndex(i);
      Navigator.pop(context); // close drawer
    }

    return Scaffold(
      appBar: AppBar(title: const Text("TrailMthr")),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "TrailMthr Menu",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Map"),
              selected: idx == 0,
              onTap: () => goTo(0),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("History"),
              selected: idx == 1,
              onTap: () => goTo(1),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text("Import"),
              selected: idx == 2,
              onTap: () => goTo(2),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              selected: idx == 3,
              onTap: () => goTo(3),
            ),
          ],
        ),
      ),
      body: pages[idx],
    );
  }
}
