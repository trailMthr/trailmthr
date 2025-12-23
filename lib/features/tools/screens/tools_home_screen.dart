import 'package:flutter/material.dart';

class ToolsHomeScreen extends StatelessWidget {
  const ToolsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tools",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Thinkspace • Notes • Checklists • Gear • Offline guides\n"
                "For now this is a placeholder. We’ll hang your thinking tools here.",
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.lightbulb_outline),
                      title: Text("Thinkspace (coming soon)"),
                    ),
                    ListTile(
                      leading: Icon(Icons.note_alt_outlined),
                      title: Text("Trail notes / diary"),
                    ),
                    ListTile(
                      leading: Icon(Icons.check_box_outlined),
                      title: Text("Checklists, packing, prep"),
                    ),
                    ListTile(
                      leading: Icon(Icons.backpack_outlined),
                      title: Text("Gear & loadouts"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
