// lib/features/thinkspace/screens/thinkspace_home_screen.dart
import 'package:flutter/material.dart';

import '../data/thinkspace_repository.dart';
import '../models/think_node.dart';
import 'think_node_detail_screen.dart';

import 'new_thought_structure_screen.dart';

import 'thinkspace_explorer_screen.dart';

class ThinkSpaceHomeScreen extends StatefulWidget {
  final ThinkSpaceRepository repository;

  const ThinkSpaceHomeScreen({
    super.key,
    required this.repository,
  });

  @override
  State<ThinkSpaceHomeScreen> createState() => _ThinkSpaceHomeScreenState();
}

class _ThinkSpaceHomeScreenState extends State<ThinkSpaceHomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _typeFilter = 'all';
  bool _loading = false;
  List<ThinkNode> _nodes = [];

  // lifecycle counts for structure section
  Map<String, int> _counts = {
    'perspectives': 0,
    'brainstorms': 0,
    'thoughts': 0,
    'concepts': 0,
    'ideas': 0,
    'quicknotes': 0,
    'archive': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadInbox();
    _loadCounts();
  }

  Future<void> _loadInbox() async {
    setState(() => _loading = true);
    try {
      _nodes = await widget.repository.searchNodes(
        query: _searchCtrl.text,
        typeFilter: _typeFilter == 'all' ? null : _typeFilter,
      );
    } catch (_) {
      // ignore for now or log
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCounts() async {
    try {
      final c = await widget.repository.getLifecycleCounts();
      if (!mounted) return;
      setState(() {
        _counts = {
          'perspectives': c['perspectives'] ?? 0,
          'brainstorms': c['brainstorms'] ?? 0,
          'thoughts': c['thoughts'] ?? 0,
          'concepts': c['concepts'] ?? 0,
          'ideas': c['ideas'] ?? 0,
          'quicknotes': c['quicknotes'] ?? 0,
          'archive': c['archive'] ?? 0,
        };
      });
    } catch (_) {
      // ignore
    }
  }

  void _openNode(ThinkNode node) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThinkNodeDetailScreen(
          repository: widget.repository,
          nodeId: node.id,
        ),
      ),
    );
    _loadInbox();
    _loadCounts();
  }

Future<void> _createNewThought() async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NewThoughtStructureScreen(
        repository: widget.repository,
        parentId: null,
      ),
    ),
  );
  // Refresh after the wizard finishes (in case a node was created)
  _loadInbox();
  _loadCounts();
}


  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // TOOLS GRID
  // ------------------------------------------------------------

  Widget _buildToolsGrid() {
    final items = <_ToolItem>[
      _ToolItem(
        icon: Icons.menu_book_rounded,
        label: 'Journal',
        onTap: _openJournal,
      ),
      _ToolItem(
        icon: Icons.calendar_month_rounded,
        label: 'Calendar',
        onTap: _openCalendar,
      ),
      _ToolItem(
        icon: Icons.list_alt_rounded,
        label: 'Lists',
        onTap: _openLists,
      ),
      _ToolItem(
        icon: Icons.dashboard_customize_rounded,
        label: 'Templates',
        onTap: _openTemplates,
      ),
      _ToolItem(
        icon: Icons.add_circle_outline_rounded,
        label: 'New Thought',
        onTap: _createNewThought,
      ),
      _ToolItem(
        icon: Icons.brush_rounded,
        label: 'Drawing Pad',
        onTap: _openDrawingPad,
      ),
      _ToolItem(
        icon: Icons.folder_open_rounded,
        label: 'Explorer',
        onTap: _openExplorer,
      ),
      _ToolItem(
        icon: Icons.flag_rounded,
        label: 'Goals',
        onTap: _openGoals,
      ),
      _ToolItem(
        icon: Icons.notifications_active_rounded,
        label: 'Reminders',
        onTap: _openReminders,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.1,
        children: items.map((item) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: item.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------------------
  // STRUCTURE SECTION
  // ------------------------------------------------------------

  Widget _buildStructureSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thought Structure',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildStructureRow(
            icon: Icons.auto_stories_rounded,
            label: 'Perspectives',
            count: _counts['perspectives'] ?? 0,
            onTap: () => _openLifecycleView('perspective'),
          ),
          _buildStructureRow(
            icon: Icons.bubble_chart_rounded,
            label: 'Brainstorms',
            count: _counts['brainstorms'] ?? 0,
            onTap: () => _openLifecycleView('brainstorm'),
          ),
          _buildStructureRow(
            icon: Icons.psychology_rounded,
            label: 'Thoughts',
            count: _counts['thoughts'] ?? 0,
            onTap: () => _openLifecycleView('thought'),
          ),
          _buildStructureRow(
            icon: Icons.psychology_rounded,
            label: 'Concepts',
            count: _counts['concepts'] ?? 0,
            onTap: () => _openLifecycleView('concept'),
          ),
          _buildStructureRow(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Ideas',
            count: _counts['ideas'] ?? 0,
            onTap: () => _openLifecycleView('idea'),
          ),
          _buildStructureRow(
            icon: Icons.bolt_rounded,
            label: 'Quick Notes',
            count: _counts['quicknotes'] ?? 0,
            onTap: () => _openLifecycleView('quicknote'),
          ),
          const Divider(height: 12),
          _buildStructureRow(
            icon: Icons.archive_rounded,
            label: 'Archive',
            count: _counts['archive'] ?? 0,
            onTap: _openArchiveView,
          ),
        ],
      ),
    );
  }

  Widget _buildStructureRow({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        count.toString(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }

  // ------------------------------------------------------------
  // SIMPLE LIFECYCLE FILTER VIEWS (STUBS)
  // ------------------------------------------------------------

  void _openLifecycleView(String lifecycle) async {
    // For now: just set typeFilter for inbox-like behavior
    setState(() {
      _typeFilter = lifecycle == 'quicknote' ? 'quicknote' : 'all';
    });
    _loadInbox();
  }

  void _openArchiveView() {
    // TODO: push a dedicated Archive screen later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Archive view not implemented yet')),
    );
  }

  // ------------------------------------------------------------
  // TOOL HANDLERS (stubbed to start)
  // ------------------------------------------------------------

  void _openJournal() {
    // Later: open filtered view of journal-type nodes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal coming soon')),
    );
  }

  void _openCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calendar coming soon')),
    );
  }

  void _openLists() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lists coming soon')),
    );
  }

  void _openTemplates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Templates coming soon')),
    );
  }

  void _openDrawingPad() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Drawing pad coming soon')),
    );
  }

  void _openExplorer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThinkSpaceExplorerScreen(
          repository: widget.repository,
        ),
      ),
    ).then((_) {
      // After coming back, refresh counts in case something changed
      _loadCounts();
      _loadInbox();
    });
  }

  void _openGoals() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goals coming soon')),
    );
  }

  void _openReminders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminders coming soon')),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ThinkSpace'),
      ),
      body: Column(
        children: [
          // TOOLS
          _buildToolsGrid(),

          // STRUCTURE
          _buildStructureSection(),

          // SEARCH + INBOX (existing behavior preserved)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search thoughts…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadInbox(),
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _nodes.isEmpty
                    ? const Center(
                        child: Text(
                          'Your mind garden is empty.\nStart planting thoughts.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: _nodes.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (context, index) {
                          final node = _nodes[index];
                          return ListTile(
                            title: Text(
                              node.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              node.preview.isEmpty
                                  ? node.type
                                  : '${node.type} • ${node.preview}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              node.lifecycleState == 'quicknote'
                                  ? Icons.bolt
                                  : Icons.chevron_right,
                            ),
                            onTap: () => _openNode(node),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
