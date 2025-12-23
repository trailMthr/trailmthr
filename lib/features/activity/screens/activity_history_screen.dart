// lib/features/activity/screens/activity_history_screen.dart

import 'package:flutter/material.dart';

import '../data/activity_repository.dart';
import 'activity_summary_screen.dart';

enum ActivitySortMode {
  newestFirst,
  oldestFirst,
  longestDistance,
  shortestDistance,
}

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() =>
   _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ActivityRepository _repo;

  bool _isLoading = true;
  List<Map<String, dynamic>> _allActivities = [];
  String _searchQuery = '';
  ActivitySortMode _sortMode = ActivitySortMode.newestFirst;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repo = ActivityRepository();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _repo.getAllActivities(); // we'll add this in repo
      setState(() {
        _allActivities = rows;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[History] Error loading activities: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredActivities {
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(_allActivities);

    // Text search (type / notes later)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) {
        final type = (a['type'] ?? '').toString().toLowerCase();
        final name = (a['name'] ?? '').toString().toLowerCase();
        return type.contains(q) || name.contains(q);
      }).toList();
    }

    // Sorting
    list.sort((a, b) {
      final aStart = (a['start_time'] as int?) ?? 0;
      final bStart = (b['start_time'] as int?) ?? 0;
      final aDist = (a['distance_m'] as num?)?.toDouble() ?? 0.0;
      final bDist = (b['distance_m'] as num?)?.toDouble() ?? 0.0;

      switch (_sortMode) {
        case ActivitySortMode.newestFirst:
          return bStart.compareTo(aStart);
        case ActivitySortMode.oldestFirst:
          return aStart.compareTo(bStart);
        case ActivitySortMode.longestDistance:
          return bDist.compareTo(aDist);
        case ActivitySortMode.shortestDistance:
          return aDist.compareTo(bDist);
      }
    });

    return list;
  }

  void _openSummary(Map<String, dynamic> activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivitySummaryScreen(
          activity: activity,

          ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RECORDS HELPERS
  // ---------------------------------------------------------------------------

  double get _totalDistanceMiles {
    return _allActivities.fold<double>(
      0.0,
      (sum, a) => sum + ((a['distance_m'] as num?)?.toDouble() ?? 0.0),
    ) /
        1609.344;
  }

  int get _totalActivitiesCount => _allActivities.length;

  Map<String, dynamic>? get _longestDistanceActivity {
    if (_allActivities.isEmpty) return null;
    return _allActivities.reduce((a, b) {
      final ad = (a['distance_m'] as num?)?.toDouble() ?? 0.0;
      final bd = (b['distance_m'] as num?)?.toDouble() ?? 0.0;
      return bd > ad ? b : a;
    });
  }

  Map<String, dynamic>? get _longestDurationActivity {
    if (_allActivities.isEmpty) return null;
    return _allActivities.reduce((a, b) {
      final ad = (a['duration_s'] as num?)?.toDouble() ?? 0.0;
      final bd = (b['duration_s'] as num?)?.toDouble() ?? 0.0;
      return bd > ad ? b : a;
    });
  }

  Map<String, dynamic>? get _fastestPaceActivity {
    final valid = _allActivities.where((a) {
      final pace = (a['avg_pace_min_per_mile'] as num?)?.toDouble() ?? 0.0;
      return pace > 0.0;
    }).toList();
    if (valid.isEmpty) return null;

    valid.sort((a, b) {
      final ap = (a['avg_pace_min_per_mile'] as num?)?.toDouble() ?? 0.0;
      final bp = (b['avg_pace_min_per_mile'] as num?)?.toDouble() ?? 0.0;
      return ap.compareTo(bp); // lower = faster
    });

    return valid.first;
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activities', icon: Icon(Icons.list_alt)),
            Tab(text: 'Records', icon: Icon(Icons.emoji_events)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivitiesTab(theme),
                _buildRecordsTab(theme),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: ACTIVITIES
  // ---------------------------------------------------------------------------

  Widget _buildActivitiesTab(ThemeData theme) {
    final items = _filteredActivities;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.hiking, size: 48),
              SizedBox(height: 12),
              Text(
                "No activities yet",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Start your first hike, run, or ride from the Activities petal.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search + Sort row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by type or name...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<ActivitySortMode>(
                icon: const Icon(Icons.sort),
                onSelected: (mode) {
                  setState(() => _sortMode = mode);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: ActivitySortMode.newestFirst,
                    child: Text('Newest first'),
                  ),
                  PopupMenuItem(
                    value: ActivitySortMode.oldestFirst,
                    child: Text('Oldest first'),
                  ),
                  PopupMenuItem(
                    value: ActivitySortMode.longestDistance,
                    child: Text('Longest distance'),
                  ),
                  PopupMenuItem(
                    value: ActivitySortMode.shortestDistance,
                    child: Text('Shortest distance'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final a = items[index];
              return _ActivityListItem(
                activity: a,
                onOpenSummary: () => _openSummary(a),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: RECORDS
  // ---------------------------------------------------------------------------

  Widget _buildRecordsTab(ThemeData theme) {
    final longestDist = _longestDistanceActivity;
    final longestDur = _longestDurationActivity;
    final fastest = _fastestPaceActivity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _RecordCard(
            title: 'Total Distance',
            value: '${_totalDistanceMiles.toStringAsFixed(1)} mi',
            subtitle: 'Across $_totalActivitiesCount activities',
          ),
          const SizedBox(height: 12),
          _RecordCard(
            title: 'Longest Distance',
            value: longestDist == null
                ? '—'
                : _formatMiles(longestDist['distance_m']),
            subtitle: longestDist == null
                ? 'No activities yet'
                : _formatDateSubtitle(longestDist),
            onTap: longestDist == null ? null : () => _openSummary(longestDist),
          ),
          const SizedBox(height: 12),
          _RecordCard(
            title: 'Longest Duration',
            value: longestDur == null
                ? '—'
                : _formatDurationSeconds(longestDur['duration_s']),
            subtitle: longestDur == null
                ? 'No activities yet'
                : _formatDateSubtitle(longestDur),
            onTap: longestDur == null ? null : () => _openSummary(longestDur),
          ),
          const SizedBox(height: 12),
          _RecordCard(
            title: 'Fastest Pace',
            value: fastest == null
                ? '—'
                : _formatPace(fastest['avg_pace_min_per_mile']),
            subtitle: fastest == null
                ? 'No valid pace data yet'
                : _formatDateSubtitle(fastest),
            onTap: fastest == null ? null : () => _openSummary(fastest),
          ),
          const SizedBox(height: 24),

          // 🔮 Future: public leaderboards stub
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.public, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Public Leaderboards (Coming Soon)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Opt-in global and local fastest times, trail segments, and seasonal leaderboards.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMiles(dynamic distanceM) {
    final d = (distanceM as num?)?.toDouble() ?? 0.0;
    final miles = d / 1609.344;
    return '${miles.toStringAsFixed(2)} mi';
  }

  String _formatDurationSeconds(dynamic seconds) {
    final s = (seconds as num?)?.toInt() ?? 0;
    final d = Duration(seconds: s);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final sec = d.inSeconds.remainder(60);

    if (h > 0) return '${h}h ${m}m ${sec}s';
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }

  String _formatPace(dynamic pace) {
    final p = (pace as num?)?.toDouble() ?? 0.0;
    if (p == 0.0) return '—';
    return '${p.toStringAsFixed(1)} min/mi';
  }

  String _formatDateSubtitle(Map<String, dynamic> activity) {
    final startMs = (activity['start_time'] as int?) ?? 0;
    if (startMs <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(startMs);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// SMALL UI COMPONENTS
// ---------------------------------------------------------------------------

class _ActivityListItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onOpenSummary;

  const _ActivityListItem({
    required this.activity,
    required this.onOpenSummary,
  });

  @override
  Widget build(BuildContext context) {
    final type = (activity['type'] ?? '').toString();
    final distanceM = (activity['distance_m'] as num?)?.toDouble() ?? 0.0;
    final durationS = (activity['duration_s'] as num?)?.toDouble() ?? 0.0;
    final pace = (activity['avg_pace_min_per_mile'] as num?)?.toDouble() ?? 0.0;
    final name = (activity['name'] ?? '').toString();

    final miles = distanceM / 1609.344;
    final d = Duration(seconds: durationS.toInt());

    IconData icon;
    switch (type) {
      case 'run':
        icon = Icons.directions_run;
        break;
      case 'bike':
        icon = Icons.directions_bike;
        break;
      case 'walk':
      default:
        icon = Icons.directions_walk;
        break;
    }

    String durationLabel;
    if (d.inHours > 0) {
      durationLabel =
          '${d.inHours}h ${d.inMinutes.remainder(60)}m ${d.inSeconds.remainder(60)}s';
    } else if (d.inMinutes > 0) {
      durationLabel = '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    } else {
      durationLabel = '${d.inSeconds}s';
    }

    final paceLabel = pace == 0.0 ? '—' : '${pace.toStringAsFixed(1)} min/mi';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onOpenSummary,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon + name/type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon),
                      const SizedBox(width: 8),
                      Text(
                        name.isNotEmpty ? name : type.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  // quick actions stubs
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.alt_route),
                        tooltip: 'Add to Route (stub)',
                        onPressed: () {
                          debugPrint(
                              '[History] Add to Route tapped for ${activity['id']}');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: 'Analyze (TrekMaster stub)',
                        onPressed: () {
                          debugPrint(
                              '[History] Analyze tapped for ${activity['id']}');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${miles.toStringAsFixed(2)} mi • $durationLabel • $paceLabel',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  const _RecordCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle),
        ],
      ),
    );

    if (onTap == null) {
      return Card(child: content);
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }
}
