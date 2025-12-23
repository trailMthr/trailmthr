import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_state.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/history/trail_history_screen.dart';
import '../../features/import/import_screen.dart';
import '../../features/settings/settings_screen.dart';

class TopNavScaffold extends StatefulWidget {
  const TopNavScaffold({super.key});

  @override
  State<TopNavScaffold> createState() => _TopNavScaffoldState();
}

class _TopNavScaffoldState extends State<TopNavScaffold> {
  late final PageController _pageController;

  final _pages = const [
    MapScreen(),
    TrailHistoryScreen(),
    ImportScreen(),
    SettingsScreen(),
  ];

  final _scrollTabs = const [
    _TabItem(icon: Icons.history, label: "History"),
    _TabItem(icon: Icons.cloud_download, label: "Import"),
    _TabItem(icon: Icons.settings, label: "Settings"),
  ];

  @override
  void initState() {
    super.initState();
    final idx = context.read<AppState>().currentIndex;
    _pageController = PageController(initialPage: idx);
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
      appBar: AppBar(
        title: const Text("TrailMthr"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Material(
            color: Colors.white,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  _FixedMapTab(
                    selected: idx == 0,
                    onTap: () => _goTo(0),
                  ),
                  const VerticalDivider(width: 1),
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
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => context.read<AppState>().setIndex(i),
        children: _pages,
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _FixedMapTab extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _FixedMapTab({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.blue : Colors.black54;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, color: color),
              const SizedBox(width: 6),
              Text("Map",
                  style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.bold : null)),
            ],
          ),
        ),
      ),
    );
  }
}

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
        width: 120,
        child: Center(
          child: Text(
            item.label,
            style: TextStyle(
              color: color,
              fontWeight: selected ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }
}
