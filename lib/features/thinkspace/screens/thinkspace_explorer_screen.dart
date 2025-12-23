import 'package:flutter/material.dart';
import '../data/thinkspace_repository.dart';
import '../models/think_node.dart';
import 'think_node_detail_screen.dart';
import 'new_thought_structure_screen.dart';

class ThinkSpaceExplorerScreen extends StatefulWidget {
  final ThinkSpaceRepository repository;

  const ThinkSpaceExplorerScreen({
    super.key,
    required this.repository,
  });

  @override
  State<ThinkSpaceExplorerScreen> createState() =>
      _ThinkSpaceExplorerScreenState();
}

class _ThinkSpaceExplorerScreenState extends State<ThinkSpaceExplorerScreen> {
  bool _loading = false;

  /// The current “path” from root → selected node
  final List<ThinkNode> _path = [];

  /// Nodes at the current level (either roots or children of the last path node)
  List<ThinkNode> _currentNodes = [];

  @override
  void initState() {
    super.initState();
    _loadLevel(null);
  }

  ThinkNode? get _currentParent =>
      _path.isEmpty ? null : _path.last;

  Future<void> _loadLevel(ThinkNode? parent) async {
    setState(() => _loading = true);
    try {
      List<ThinkNode> nodes;
      if (parent == null) {
        nodes = await widget.repository.getRootNodes();
      } else {
        nodes = await widget.repository.getChildren(parent.id);
        // Hide archived children
        nodes = nodes.toList();
      }

      if (!mounted) return;
      setState(() {
        _currentNodes = nodes;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _enterNode(ThinkNode node) {
    setState(() {
      _path.add(node);
    });
    _loadLevel(node);
  }

  void _popLevel() {
    if (_path.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _path.removeLast();
    });
    _loadLevel(_path.isEmpty ? null : _path.last);
  }

  Future<void> _openNodeDetail(ThinkNode node) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThinkNodeDetailScreen(
          repository: widget.repository,
          nodeId: node.id,
        ),
      ),
    );
    // After edits, reload current level
    _loadLevel(_currentParent);
  }

  Future<void> _createChildHere() async {
    final parent = _currentParent;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewThoughtStructureScreen(
          repository: widget.repository,
          parentId: parent?.id,
        ),
      ),
    );
    _loadLevel(parent);
  }

  String _buildBreadcrumbLabel() {
    if (_path.isEmpty) return 'Root';
    return _path.map((n) => n.title).join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final parent = _currentParent;

    return WillPopScope(
      onWillPop: () async {
        if (_path.isNotEmpty) {
          _popLevel();
          return false;
        }
// At root of ThinkSpace — DO NOT exit app here
return false;

      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _popLevel,
          ),
          title: const Text('Explorer'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(32),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _buildBreadcrumbLabel(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            if (parent != null)
              _ExplorerParentCard(
                node: parent,
                onOpenDetail: () => _openNodeDetail(parent),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentNodes.isEmpty
                      ? Center(
                          child: Text(
                            parent == null
                                ? 'No root thoughts yet.\nCreate one to begin your mind tree.'
                                : 'No children here yet.\nAdd a new thought branching from this one.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _currentNodes.length,
                          itemBuilder: (context, index) {
                            final node = _currentNodes[index];
                            return _ExplorerNodeCard(
                              node: node,
                              onTap: () => _enterNode(node),
                              onOpenDetail: () => _openNodeDetail(node),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createChildHere,
          icon: const Icon(Icons.add),
          label: Text(
            parent == null ? 'New Root Thought' : 'Add Child Thought',
          ),
        ),
      ),
    );
  }
}

class _ExplorerParentCard extends StatelessWidget {
  final ThinkNode node;
  final VoidCallback onOpenDetail;

  const _ExplorerParentCard({
    super.key,
    required this.node,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: ListTile(
        title: Text(
          node.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          node.preview.isEmpty ? node.type : node.preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton(
          onPressed: onOpenDetail,
          child: const Text('Open'),
        ),
      ),
    );
  }
}

class _ExplorerNodeCard extends StatelessWidget {
  final ThinkNode node;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  const _ExplorerNodeCard({
    super.key,
    required this.node,
    required this.onTap,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final childrenBadge =
        node.childCount > 0 ? 'Children: ${node.childCount}' : null;
    final linksBadge = node.links.isNotEmpty
        ? 'Links: ${node.links.length}'
        : null;

    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconForLifecycle(node.lifecycleState),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      node.preview.isEmpty
                          ? node.type
                          : node.preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (childrenBadge != null)
                          _chip(context, childrenBadge),
                        if (linksBadge != null)
                          _chip(context, linksBadge),
                        _chip(
                          context,
                          node.lifecycleState,
                        ),
                        _chip(
                          context,
                          node.functionType,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: onOpenDetail,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context)
            .colorScheme
            .surfaceVariant,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  static IconData _iconForLifecycle(String state) {
    switch (state) {
      case 'perspective':
        return Icons.auto_stories_rounded;
      case 'brainstorm':
        return Icons.bubble_chart_rounded;
      case 'thought':
        return Icons.psychology_rounded;
      case 'concept':
        return Icons.category_rounded;
      case 'quicknote':
        return Icons.bolt_rounded;
      case 'idea':
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }
}
