import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_state.dart';

// Screens
import '../../features/map/screens/map_screen.dart';
import '../../features/history/trail_history_screen.dart';
import '../../features/plan/plan_screen.dart';
import '../../features/settings/settings_screen.dart';

// NEW — Notes root (with Notes / Diary / Reminders)
import '../../features/notes/screens/notes_root_screen.dart';

class BottomNavScaffold extends StatefulWidget {
  const BottomNavScaffold({super.key});

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  late final PageController _pageController;

  /// PAGE ORDER (UPDATED)
  /// 0 = Map
  /// 1 = History
  /// 2 = TrekMaster
  /// 3 = Notes (3-tab NotesRootScreen)
  /// 4 = Settings
  final _pages = const [
    MapScreen(),
    TrailHistoryScreen(),
    PlanScreen(),
    NotesRootScreen(),  // <--- UPDATED
    SettingsScreen(),
  ];

  /// SCROLLABLE TABS (UPDATED)
  final _scrollTabs = const [
    _TabItem(icon: Icons.history, label: "History"),
    _TabItem(icon: Icons.hiking, label: "TrekMaster"),
    _TabItem(icon: Icons.menu_book_rounded, label: "Notes"), // <--- UPDATED
    _TabItem(icon: Icons.settings, label: "Settings"),
  ];

  @override
  void initState() {
    super.initState();
    final startIdx = context.read<AppState>().currentIndex;
    _pageController = PageController(initialPage: startIdx);
  }

  void _goTo(int index) {
    context.read<AppState>().setIndex(index);
    _pageController.jumpToPage(index);
    setState(() {}); // update selected highlight
  }

  @override
  Widget build(BuildContext context) {
    final idx = context.watch<AppState>().currentIndex;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          context.read<AppState>().setIndex(i);

          // Clear selected trail when leaving Map screen
          if (i != 0) {
            context.read<AppState>().setSelectedTrail(null);
          }

          setState(() {});
        },
        children: _pages,
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          elevation: 10,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                // ---------- FIXED MAP TAB ----------
                _FixedMapTab(
                  selected: idx == 0,
                  onTap: () => _goTo(0),
                ),

                const VerticalDivider(width: 1),

                // ---------- SCROLLABLE TABS ----------
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _scrollTabs.length,
                    itemBuilder: (_, i) {
                      final pageIndex = i + 1; // offset (0 is Map)
                      final item = _scrollTabs[i];
                      final selected = idx == pageIndex;

                      return _ScrollTab(
                        item: item,
                        selected: selected,
                        onTap: () => _goTo(pageIndex),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// HELPERS
// ======================================================

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

// ---------- FIXED MAP TAB ----------

class _FixedMapTab extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _FixedMapTab({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.blue : Colors.black54;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, color: color),
            const SizedBox(height: 4),
            Text(
              "Map",
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 36 : 0,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- SCROLLABLE TABS ----------

class _ScrollTab extends StatelessWidget {
  final _TabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _ScrollTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.blue : Colors.black54;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(height: 6),

            // Underline animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 36 : 0,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
