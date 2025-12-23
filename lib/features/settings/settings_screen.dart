import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final style = appState.navStyle;

    return Column(
      children: [
        // Simulated AppBar
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4,
                color: Colors.black12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            "Settings",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: 8),
              const ListTile(
                title: Text(
                  "Navigation Style",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              RadioListTile<NavigationStyle>(
                value: NavigationStyle.bottom,
                groupValue: style,
                title: const Text("Bottom (default)"),
                subtitle: const Text("Fixed Map tab + scrollable tabs on bottom"),
                onChanged: (v) => appState.setNavStyle(v!),
              ),
              RadioListTile<NavigationStyle>(
                value: NavigationStyle.top,
                groupValue: style,
                title: const Text("Top"),
                subtitle: const Text("Fixed Map tab + scrollable tabs under AppBar"),
                onChanged: (v) => appState.setNavStyle(v!),
              ),
              RadioListTile<NavigationStyle>(
                value: NavigationStyle.sidebar,
                groupValue: style,
                title: const Text("Side Drawer"),
                subtitle: const Text("Hamburger menu navigation"),
                onChanged: (v) => appState.setNavStyle(v!),
              ),

              const Divider(),

              const ListTile(
                title: Text("More settings coming soon…"),
                subtitle: Text(
                  "Units, auto-pause threshold, map styles, offline packs",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
