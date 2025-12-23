import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:trailmthr_test2/features/map/screens/map_screen.dart';
import 'package:trailmthr_test2/features/tools/screens/tools_home_screen.dart';
import 'package:trailmthr_test2/features/community/screens/community_home_screen.dart';
import 'package:trailmthr_test2/features/actions/trail_action_engine.dart';

import 'package:trailmthr_test2/main_app_shell.dart';

import 'package:trailmthr_test2/main_app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrailMthrApp());
}

class TrailMthrApp extends StatelessWidget {
  const TrailMthrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrailMthr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainAppShell(

      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 1; // 0: Tools, 1: Map, 2: Community

  final GlobalKey<NavigatorState> _toolsNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _mapNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _communityNavKey =
      GlobalKey<NavigatorState>();

  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    // Allow the map to tell us "user touched map" so we can collapse the FAB row.
    TrailActionEngine.instance.onMapInteraction = _handleMapInteractionFromMap;
  }

  void _handleMapInteractionFromMap() {
    if (!mounted) return;
    if (_currentIndex == 1 && _fabExpanded) {
      setState(() {
        _fabExpanded = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    NavigatorState currentNav;
    switch (_currentIndex) {
      case 0:
        currentNav = _toolsNavKey.currentState!;
        break;
      case 1:
        currentNav = _mapNavKey.currentState!;
        break;
      case 2:
      default:
        currentNav = _communityNavKey.currentState!;
        break;
    }

    if (currentNav.canPop()) {
      currentNav.pop();
      return false;
    }

    // If not on Map tab, go back to Map instead of exiting
    if (_currentIndex != 1) {
      setState(() => _currentIndex = 1);
      return false;
    }

  // MapScreen does not control app exit
  return false;
  }

Widget _buildTabNavigator({
  required int tabIndex,
  required GlobalKey<NavigatorState> navKey,
  required Widget rootScreen,
}) {
  return Navigator(
    key: navKey,
    onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
        builder: (_) => rootScreen,
        settings: settings,
      );
    },
  );
}


  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Tapping active tab pops to root of that tab
      NavigatorState nav;
      switch (index) {
        case 0:
          nav = _toolsNavKey.currentState!;
          break;
        case 1:
          nav = _mapNavKey.currentState!;
          break;
        case 2:
        default:
          nav = _communityNavKey.currentState!;
          break;
      }
      while (nav.canPop()) {
        nav.pop();
      }
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _openAdvancedMenu() {
    HapticFeedback.heavyImpact();
    final engine = TrailActionEngine.instance;
    final sections = engine.buildAdvancedSections();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 1.0,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TrailMthr tools',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final section in sections) ...[
                    _AdvancedSectionHeader(
                      icon: section.icon,
                      label: section.title,
                    ),
                    const SizedBox(height: 4),
                    for (final item in section.items)
                      ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.title),
                        subtitle:
                            item.subtitle != null ? Text(item.subtitle!) : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          item.onTap(context);
                        },
                      ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapFab() {
    final engine = TrailActionEngine.instance;
    final quickActions = engine.quickActions;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding + 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_fabExpanded && quickActions.isNotEmpty)
            ...quickActions
                .map(
                  (qa) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _QuickActionChip(action: qa),
                  ),
                )
                .toList(),

        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: _onWillPop,
    child: Scaffold(
      body: Stack(
        children: [

          // ✅ FORCE FULL-SCREEN TAB CONTENT
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildTabNavigator(
                  tabIndex: 0,
                  navKey: _toolsNavKey,
                  rootScreen: const ToolsHomeScreen(),
                ),
                _buildTabNavigator(
                  tabIndex: 1,
                  navKey: _mapNavKey,
                  rootScreen: const MainAppShell(),
                ),
                _buildTabNavigator(
                  tabIndex: 2,
                  navKey: _communityNavKey,
                  rootScreen: const CommunityHomeScreen(),
                ),
              ],
            ),
          ),



            // Floating Settings bubble (top-left)
            Positioned(
              top: 40,
              left: 16,
              child: _CornerBubble(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => const _PlaceholderSheet(
                      title: 'Settings (coming soon)',
                    ),
                  );
                },
              ),
            ),

            // Floating Profile bubble (top-right)
            Positioned(
              top: 40,
              right: 16,
              child: _CornerBubble(
                icon: Icons.person,
                label: 'Profile',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => const _PlaceholderSheet(
                      title: 'Profile (coming soon)',
                    ),
                  );
                },
              ),
            ),

            // tM FAB + quick actions, only on Map tab
            if (_currentIndex == 1)
              Positioned(
                right: 16,
                bottom: 16,
                child: _buildMapFab(),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: 'Tools',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Community',
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CornerBubble({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderSheet extends StatelessWidget {
  final String title;

  const _PlaceholderSheet({required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 200,
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final TrailQuickAction action;

  const _QuickActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await action.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: Icon(action.icon, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            action.label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AdvancedSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AdvancedSectionHeader({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
