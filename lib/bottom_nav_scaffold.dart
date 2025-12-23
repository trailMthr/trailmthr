import 'package:flutter/material.dart';

// Screens
import 'features/map/screens/map_screen.dart';
import 'features/history/trail_history_screen.dart';
import 'features/import/import_screen.dart';
import 'features/notes/screens/notes_screen.dart';

// Thought system
import 'features/thoughts/screens/think_space_screen.dart';
import 'features/thoughts/screens/bubble_graph_screen.dart';

class BottomNavScaffold extends StatefulWidget {
  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  int _index = 0;

  // IMPORTANT: Thought tab now shows a MENU instead of graph alone
  final screens = const [
    MapScreen(),
    NotesScreen(),
    ThoughtHomeScreen(),  // <── NEW HOME SCREEN FOR THOUGHT SYSTEM
    TrailHistoryScreen(),
    ImportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.bubble_chart_outlined),
            selectedIcon: Icon(Icons.bubble_chart),
            label: 'Thoughts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.file_upload_outlined),
            selectedIcon: Icon(Icons.file_upload),
            label: 'Import',
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------
// NEW SCREEN: Thought Home Menu (fixes blank page issue)
// --------------------------------------------------------------
class ThoughtHomeScreen extends StatelessWidget {
  const ThoughtHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thoughts")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Enter Think Space"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThinkSpaceScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.bubble_chart),
              label: const Text("View Thought Network"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BubbleGraphScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
