// lib/features/activity/widgets/start_activity_sheet.dart
// Half-screen Start Activity command panel (auto-dismiss on Start)

import 'package:flutter/material.dart';
import '../controllers/live_activity_controller.dart';
import '../models/tracking_mode.dart';

class StartActivitySheet extends StatefulWidget {
  final LiveActivityController controller;
  final VoidCallback onAddRoute; // hook to route planner
final Future<void> Function(TrackingMode mode) onStart;
final VoidCallback onOpenHistory;

  const StartActivitySheet({
    super.key,
    required this.controller,
    required this.onAddRoute,
    required this.onStart,
    required this.onOpenHistory,
  });

  @override
  State<StartActivitySheet> createState() => _StartActivitySheetState();
}

class _StartActivitySheetState extends State<StartActivitySheet> {
  TrackingMode? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.selectedMode;
  }

void _start() async {
  if (_selected == null) return;

  // 🛡 Ensure everything is configured correctly first
  final ok = await widget.controller.ensureRecordingReady(context);
  if (!ok) {
    // Do NOT dismiss the sheet — user may need to read instructions
    return;
  }

  // ▶️ Safe to start
  await widget.onStart(_selected!);

  if (mounted) {
    Navigator.of(context).pop();
  }
}



  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.50,
      minChildSize: 0.35,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(blurRadius: 14, color: Colors.black26),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --------------------------------------------------
                // DRAG LIP
                // --------------------------------------------------
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Start Activity',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    TextButton.icon(
      icon: const Icon(Icons.history),
      label: const Text('History'),
      onPressed: () {
        // Close the sheet, then open full-screen History
        Navigator.of(context).pop();
        widget.onOpenHistory();
      },
    ),
  ],
),

const SizedBox(height: 12),

                // --------------------------------------------------
                // MODE SELECTION
                // --------------------------------------------------
                _ModeTile(
                  label: 'Hike',
                  icon: Icons.directions_walk,
                  selected: _selected == TrackingMode.walk,
                  onTap: () => setState(() => _selected = TrackingMode.walk),
                ),
                _ModeTile(
                  label: 'Run',
                  icon: Icons.directions_run,
                  selected: _selected == TrackingMode.run,
                  onTap: () => setState(() => _selected = TrackingMode.run),
                ),
                _ModeTile(
                  label: 'Bike',
                  icon: Icons.directions_bike,
                  selected: _selected == TrackingMode.bike,
                  onTap: () => setState(() => _selected = TrackingMode.bike),
                ),

                const SizedBox(height: 18),

                // --------------------------------------------------
                // SETTINGS (WIRED TO CONTROLLER)
                // --------------------------------------------------
                const Text(
                  'Settings',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 6),

                SwitchListTile(
                  title: const Text('Auto-pause'),
                  value: widget.controller.autoPause,
                  onChanged: (v) {
                    setState(() => widget.controller.autoPause = v);
                    widget.controller.notifyListeners();
                  },
                ),

                SwitchListTile(
                  title: const Text('Share live location'),
                  value: widget.controller.shareLiveLocation,
                  onChanged: (v) {
                    setState(() => widget.controller.shareLiveLocation = v);
                    widget.controller.notifyListeners();
                  },
                ),

                SwitchListTile(
                  title: const Text('Lap / distance sounds'),
                  value: widget.controller.lapSounds,
                  onChanged: (v) {
                    setState(() => widget.controller.lapSounds = v);
                    widget.controller.notifyListeners();
                  },
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------
                // ACTION BUTTONS
                // --------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        onPressed: _selected == null ? null : _start,
                      ),
                    ),

                    const SizedBox(width: 12),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.alt_route),
                      label: const Text('Add Route'),
                      onPressed: widget.onAddRoute,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// MODE SELECT TILE
// ------------------------------------------------------------

class _ModeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 3 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: selected ? const Icon(Icons.check_circle) : null,
        onTap: onTap,
      ),
    );
  }
}
