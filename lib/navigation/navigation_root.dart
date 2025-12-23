import 'package:trailmthr_test2/features/notes/screens/notes_list_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'nav_styles/bottom_nav.dart';
import 'nav_styles/top_nav.dart';
import 'nav_styles/side_nav.dart';

class NavigationRoot extends StatelessWidget {
  const NavigationRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final style = context.watch<AppState>().navStyle;

    switch (style) {
      case NavigationStyle.bottom:
        return const BottomNavScaffold();
      case NavigationStyle.top:
        return const TopNavScaffold();
      case NavigationStyle.sidebar:
        return const SideNavScaffold();
    }
  }
}
