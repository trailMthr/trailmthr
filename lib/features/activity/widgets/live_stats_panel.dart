// lib/features/activity/widgets/live_stats_panel.dart
// Recording-only auto-opening quarter-screen stats dock with vertical 2x2 scroll grid

import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/live_activity_controller.dart';
import '../../activity/controllers/activity_recorder.dart';

class LiveStatsPanel extends StatefulWidget {
  final LiveActivityController controller;
  final ActivityRecorder recorder;
  final Future<void> Function() onStop;

  const LiveStatsPanel({
    super.key,
    required this.controller,
    required this.recorder,
    required this.onStop,
  });


  @override
  State<LiveStatsPanel> createState() => _LiveStatsPanelState();
}

class _LiveStatsPanelState extends State<LiveStatsPanel> {

  late final StreamSubscription _recorderSub;
  late RecorderState _latestState;

  bool _detailMode = false;
  String _detailKey = 'time';

  @override
  void initState() {
    super.initState();

    _latestState = RecorderState.initial();


    _recorderSub = widget.recorder.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _latestState = state;
      });
    });
  }

  @override
  void dispose() {

    _recorderSub.cancel();

    super.dispose();
  }


Future<void> _confirmStop() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('End Activity?'),
      content: const Text(
        'This will finish and save your activity.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Finish'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // 🔴 STEP 1: enter finalizing state immediately
  widget.controller.beginFinalizing();

  // 🔴 STEP 2: persist + navigate (external responsibility)
  // This should:
  // - save activity to DB
  // - Navigator.pushReplacement to summary
  await widget.onStop();

  // 🔴 STEP 3: mark finalized + hard reset live UI
  widget.controller.markFinalized();
  widget.controller.reset();
}

@override
Widget build(BuildContext context) {
  final c = widget.controller;

  // PANEL EXISTS ONLY WHEN RECORDING
  if (!c.isLive) return const SizedBox.shrink();

  final distanceMiles = _latestState.distanceM / 1609.344;
  final double pace = distanceMiles > 0
      ? (_latestState.durationS / 60.0) / distanceMiles
      : 0.0;

  final modeLabel = _latestState.mode.name;

  return AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final elapsed = widget.controller.elapsed;

      final hh = elapsed.inHours.toString().padLeft(2, '0');
      final mm = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

      final timeText =
          elapsed.inHours > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
      return WillPopScope(
        onWillPop: () async {
          // 🔴 Activity UI must NEVER exit the app
          // Let MainAppShell decide what to do
          return false;
        },
        child: DraggableScrollableSheet(
          initialChildSize: c.statsPanelExtent,
          minChildSize: 0.25,
          maxChildSize: 0.75,
          snap: true,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // --------------------------------------------------
                  // TOP CONTROL BAR
                  // --------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if(c.isPaused) {
                              widget.recorder.unpause();
                            } else {
                              widget.recorder.pause();
                            }
                          },
                          icon: Icon(
                            c.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                          ),
                          label: Text(
                            c.isPaused ? 'Resume' : 'Pause',
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _confirmStop,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // --------------------------------------------------
                  // BODY
                  // --------------------------------------------------
                  Expanded(
                    child: _detailMode
                        ? _buildDetailView(context)
                        : _buildOverviewGrid(
                            scrollController,
                            time: _formatDuration(widget.controller.elapsed),
                            distance:
                                '${distanceMiles.toStringAsFixed(2)} mi',
                            pace: pace == 0
                                ? '—'
                                : '${pace.toStringAsFixed(1)} min/mi',
                            mode: modeLabel,
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

  // ------------------------------------------------------------
  // OVERVIEW GRID (VERTICAL 2x2 SCROLLABLE)
  // ------------------------------------------------------------

  Widget _buildOverviewGrid(
    ScrollController controller, {
    required String time,
    required String distance,
    required String pace,
    required String mode,
  }) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatButton(label: 'Time', value: time, onTap: () => _openDetail('time')),
          _StatButton(label: 'Distance', value: distance, onTap: () => _openDetail('distance')),
          _StatButton(label: 'Pace', value: pace, onTap: () => _openDetail('pace')),
          _StatButton(label: 'Mode', value: mode, onTap: () => _openDetail('mode')),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DETAIL MODE
  // ------------------------------------------------------------

  Widget _buildDetailView(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _detailMode = false),
              ),
              const SizedBox(width: 8),
              Text(
                _detailKey.toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        const Expanded(
          child: Center(
            child: Text(
              'Trend & analysis coming soon',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  void _openDetail(String key) {
    setState(() {
      _detailKey = key;
      _detailMode = true;
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

// ------------------------------------------------------------
// STAT BUTTON
// ------------------------------------------------------------

class _StatButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }
}