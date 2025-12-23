import 'package:flutter/material.dart';
import 'package:trailmthr_test2/features/thinkspace/data/thinkspace_repository.dart';

class ActivitySummaryScreen extends StatefulWidget {
  final Map<String, dynamic> activity;
  final ThinkSpaceRepository? thinkRepo;

  const ActivitySummaryScreen({
    super.key,
    required this.activity,
    this.thinkRepo,
  });

  @override
  State<ActivitySummaryScreen> createState() =>
      _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen> {
  Future<void> _addToThinkSpace() async {
    final a = widget.activity;

    if (widget.thinkRepo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ThinkSpace not available")),
      );
      return;
    }

    final distanceMiles =
        ((a['distance_m'] ?? 0) / 1609.344);

    final durationMin =
        ((a['duration_s'] ?? 0) / 60).round();

    final summary =
        "${a['name'] ?? 'Activity'} — "
        "${distanceMiles.toStringAsFixed(2)} mi, "
        "$durationMin min";

    await widget.thinkRepo!.createNode(
      type: 'activity',
      content: summary,
      activityId: a['id'],
      lifecycleState: 'idea',
      functionType: 'summary',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to ThinkSpace")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;

    final double distanceM =
        (a['distance_m'] as num?)?.toDouble() ?? 0.0;
    final double durationS =
        (a['duration_s'] as num?)?.toDouble() ?? 0.0;
    final double avgPace =
        (a['avg_pace_min_per_mile'] as num?)?.toDouble() ?? 0.0;

    final double distanceMiles = distanceM / 1609.344;
    final duration = Duration(seconds: durationS.toInt());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity Summary"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------------------
              // ✅ CORE STATS
              // ------------------------------------------------------------
              _StatCard(
                title: "Distance",
                value: "${distanceMiles.toStringAsFixed(2)} mi",
              ),
              _StatCard(
                title: "Duration",
                value: _formatDuration(duration),
              ),
              _StatCard(
                title: "Avg Pace",
                value: avgPace == 0
                    ? "—"
                    : "${avgPace.toStringAsFixed(1)} min/mi",
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------------------
              // ✅ NOTES INPUT
              // ------------------------------------------------------------
              const Text(
                "Notes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Reflection, trail conditions, thoughts…",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------------------
              // 🔮 FUTURE PLACEHOLDERS
              // ------------------------------------------------------------
              const _PlaceholderPanel(
                title: "Map Replay (Coming Soon)",
                height: 160,
                description:
                    "Full route playback with elevation + pace overlays",
              ),
              const SizedBox(height: 20),
              const _PlaceholderPanel(
                title: "Elevation Profile (Coming Soon)",
                height: 120,
                description: "Gain/loss curve and climb segments",
              ),
              const SizedBox(height: 20),
              const _PlaceholderPanel(
                title: "TrekMaster Analysis (Offline AI)",
                height: 120,
                description:
                    "Future: stride efficiency, fatigue modeling, terrain adaptation",
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------------------
              // ✅ ACTION BUTTONS
              // ------------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Save Activity"),
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text("Analyze"),
                    onPressed: null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.psychology),
                label: const Text("Add to ThinkSpace"),
                onPressed: _addToThinkSpace,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) return "${h}h ${m}m ${s}s";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }
}

// ---------------------------------------------------------------------------
// UI COMPONENTS
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  final String title;
  final double height;
  final String description;

  const _PlaceholderPanel({
    required this.title,
    required this.height,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: theme.hintColor)),
        ],
      ),
    );
  }
}
