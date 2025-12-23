import 'package:flutter/material.dart';

class TrekMasterHomeScreen extends StatelessWidget {
  const TrekMasterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TrekMaster"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Trail AI Command Center",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              "Future capabilities:",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),

            _featureTile("Route planning & optimization"),
            _featureTile("Performance analysis"),
            _featureTile("Weather-aware rerouting"),
            _featureTile("Training + recovery suggestions"),
            _featureTile("Diary + map pattern analysis"),
            _featureTile("Treasure hunt + geocache logic"),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("AI core coming online soon 👀")),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Activate TrekMaster"),
            )
          ],
        ),
      ),
    );
  }

  Widget _featureTile(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
