// lib/features/map/widgets/point_sheet.dart
import 'package:flutter/material.dart';
import '../../../models/trail_point.dart';

class PointDetailSheet extends StatelessWidget {
  final TrailPoint point;
  final VoidCallback? onGoTo;

  const PointDetailSheet({
    super.key,
    required this.point,
    this.onGoTo,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(point.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (point.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(point.description!,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onGoTo,
                  icon: const Icon(Icons.map),
                  label: const Text('Go to This Point'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // future: start navigation/recording
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature upcoming')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
