import 'package:flutter/material.dart';
import '../data/thinkspace_repository.dart';
import '../models/think_node.dart';

import '../ai/thinkspace_ai.dart';

class ThinkSpaceRelationshipPanel extends StatefulWidget {
  final ThinkSpaceRepository repository;
  final ThinkNode node;

  const ThinkSpaceRelationshipPanel({
    super.key,
    required this.repository,
    required this.node,
  });

  @override
  State<ThinkSpaceRelationshipPanel> createState() =>
      _ThinkSpaceRelationshipPanelState();
}

class _ThinkSpaceRelationshipPanelState
    extends State<ThinkSpaceRelationshipPanel> {
  List<ThinkNode> _children = [];
  List<ThinkNode> _siblings = [];
  ThinkNode? _parent;

  String _childSortMode = 'updated_desc';

  @override
  void initState() {
    super.initState();
    _loadRelationships();
  }

  Future<void> _loadRelationships() async {
    final repo = widget.repository;
    final node = widget.node;

    // Parent
    if (node.parentId != null) {
      _parent = await repo.getNode(node.parentId!);
    }

    // Children
    _children = await repo.getChildren(node.id);
    _applyChildSorting();

    // Siblings = parent’s children except this node
    if (_parent != null) {
      final all = await repo.getChildren(_parent!.id);
      _siblings = all.where((n) => n.id != node.id).toList();
    }

    if (mounted) setState(() {});
  }

  void _applyChildSorting() {
    switch (_childSortMode) {
      case 'updated_desc':
        _children.sort((a, b) => b.updated.compareTo(a.updated));
        break;
      case 'updated_asc':
        _children.sort((a, b) => a.updated.compareTo(b.updated));
        break;
      case 'created_asc':
        _children.sort((a, b) => a.created.compareTo(b.created));
        break;
    }
  }

  Future<void> _createChild() async {
    final repo = widget.repository;

    final newChild = await repo.createNode(
      parentId: widget.node.id,
      type: "idea",
      content: "",
    );

    await _loadRelationships();
    final ai = ThinkSpaceAI(widget.repository);

if (widget.node == null) return;

final node = widget.node!;

final newLifecycle = await ai.inferLifecycle(node);

await widget.repository.updateNode(
  node.copyWith(lifecycleState: newLifecycle),
);

  }

  Future<void> _createSibling() async {
    if (_parent == null) return;

    final repo = widget.repository;

    await repo.createNode(
      parentId: _parent!.id,
      type: "idea",
      content: "",
    );

    await _loadRelationships();
    final ai = ThinkSpaceAI(widget.repository);
final newLifecycle = await ai.inferLifecycle(widget.node);
await widget.repository.updateNode(widget.node.copyWith(lifecycleState: newLifecycle));

  }

  Future<void> _reassignParent() async {
    // TODO: implement UI to pick a new parent
    // placeholder for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Parent reassignment coming soon")),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.94,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  "Connections",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 18),

                // Parent
                _buildCard(
                  title: "Parent",
                  child: _parent == null
                      ? const Text("None")
                      : ListTile(
                          title: Text(_parent!.title),
                          subtitle: Text(_parent!.type),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                ),

                // Siblings
                _buildCard(
                  title: "Siblings",
                  child: _siblings.isEmpty
                      ? const Text("None")
                      : Column(
                          children: _siblings
                              .map(
                                (s) => ListTile(
                                  title: Text(s.title),
                                  subtitle: Text(s.type),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              )
                              .toList(),
                        ),
                ),

                // ------------ CHILDREN SECTION ------------

                _buildCard(
                  title: "Children",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sort dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sort"),
                          DropdownButton<String>(
                            value: _childSortMode,
                            items: const [
                              DropdownMenuItem(
                                value: 'updated_desc',
                                child: Text('Updated (newest)'),
                              ),
                              DropdownMenuItem(
                                value: 'updated_asc',
                                child: Text('Updated (oldest)'),
                              ),
                              DropdownMenuItem(
                                value: 'created_asc',
                                child: Text('Created (oldest)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _childSortMode = value;
                                _applyChildSorting();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_children.isEmpty)
                        const Text("No children")
                      else
                        Column(
                          children: _children
                              .map(
                                (c) => ListTile(
                                  title: Text(c.title),
                                  subtitle: Text(c.type),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              )
                              .toList(),
                        ),

                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _createChild,
                          icon: const Icon(Icons.add),
                          label: const Text("Add Child Thought"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ACTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _createSibling,
                        icon: const Icon(Icons.group_add),
                        label: const Text("Add Sibling"),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _reassignParent,
                        icon: const Icon(Icons.swap_calls),
                        label: const Text("Reassign Parent"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
