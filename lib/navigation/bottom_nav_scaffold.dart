import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// App state for active tab + map selections
import '../navigation/app_state.dart';

// Screens
import '../features/map/screens/map_screen.dart';
import '../features/history/trail_history_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/notes/screens/notes_list_screen.dart';
import '../features/settings/settings_screen.dart';

class BottomNavScaffold extends StatefulWidget {
  BottomNavScaffold({super.key});

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  late final PageController _pageController;

  /// ORDER OF PAGES:
  /// 0 = Map
  /// 1 = History
  /// 2 = Plan / TrekMaster
  /// 3 = Notes
  /// 4 = Settings
  final _pages = const [
    MapScreen(),
    TrailHistoryScreen(),
    PlanScreen(),
    NotesListScreen(),
    SettingsScreen(),
  ];

  /// SCROLLABLE TABS (right side)
  final _scrollTabs = const [
    _TabItem(icon: Icons.history, label: "History"),
    _TabItem(icon: Icons.hiking, label: "TrekMaster"),
    _TabItem(icon: Icons.menu_book_rounded, label: "Notes"),
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
    setState(() {});
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

          // Clear selected trail when leaving the Map
          if (i != 0) {
            context.read<AppState>().setSelectedTrail(null);
          }

          setState(() {});
        },
        children: _pages,
      ),

      bottomNavigationBar: SafeArea(
        child: Material(
          elevation: 12,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                // ---- FIXED MAP TAB ----
                _FixedMapTab(
                  selected: idx == 0,
                  onTap: () => _goTo(0),
                ),

                const VerticalDivider(width: 1),

                // ---- SCROLLABLE RIGHT TABS ----
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _scrollTabs.length,
                    itemBuilder: (_, i) {
                      final pageIndex = i + 1;
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

// -------------------------------------------------------------
// INTERNAL WIDGETS
// -------------------------------------------------------------

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

// ---- FIXED MAP TAB ----

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
            const SizedBox(height: 2),
            Text(
              "Map",
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 35 : 0,
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

// ---- SLIDING SCROLLABLE TABS ----

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
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 35 : 0,
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
