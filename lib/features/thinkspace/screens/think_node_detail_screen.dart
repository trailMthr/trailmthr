import 'package:flutter/material.dart';
import '../data/thinkspace_repository.dart';
import '../models/think_node.dart';

import '../widgets/thinkspace_relationship_panel.dart';
import '../widgets/thinkspace_properties_panel.dart';

import '../ai/thinkspace_ai.dart';

class ThinkNodeDetailScreen extends StatefulWidget {
  final ThinkSpaceRepository repository;
  final String nodeId;

  const ThinkNodeDetailScreen({
    super.key,
    required this.repository,
    required this.nodeId,
  });

  @override
  State<ThinkNodeDetailScreen> createState() => _ThinkNodeDetailScreenState();
}

class _ThinkNodeDetailScreenState extends State<ThinkNodeDetailScreen> {
  ThinkNode? _node;
  late final TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController();
    _loadNode();
  }

  Future<void> _loadNode() async {
    final node = await widget.repository.getNode(widget.nodeId);
    if (mounted && node != null) {
      setState(() => _node = node);
      _contentCtrl.text = node.content;
    }
  }

  Future<void> _saveContent() async {
    if (_node == null) return;

    final updated = _node!.copyWith(
      content: _contentCtrl.text,
      updated: DateTime.now(),
    );

    setState(() => _saving = true);
//
final ai = ThinkSpaceAI(widget.repository);

if (_node == null) return; // safety guard

final node = _node!; // promote non-null

final newLifecycle = await ai.inferLifecycle(node);

await widget.repository.updateNode(
  node.copyWith(lifecycleState: newLifecycle),
);

    await widget.repository.updateNode(updated);
    setState(() => _saving = false);

    _node = updated; // keep local copy fresh
  }

  void _openRelationshipsPanel() {
    if (_node == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThinkSpaceRelationshipPanel(
        repository: widget.repository,
        node: _node!,
      ),
    ).then((_) => _loadNode()); // refresh after modifications
  }

  void _openPropertiesPanel() {
    if (_node == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThinkSpacePropertiesPanel(
        repository: widget.repository,
        node: _node!,
      ),
    ).then((_) => _loadNode()); // refresh properties
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_node == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _node!.title.isEmpty ? "Untitled Thought" : _node!.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: "Properties",
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openPropertiesPanel,
          ),
          IconButton(
            tooltip: "Connections",
            icon: const Icon(Icons.hub_rounded),
            onPressed: _openRelationshipsPanel,
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: SingleChildScrollView(
          child: TextField(
            controller: _contentCtrl,
            maxLines: null,
            autofocus: true,
            onChanged: (_) => _saveContent(), // autosave on type
            style: const TextStyle(fontSize: 16, height: 1.4),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Start writing your thought…",
            ),
          ),
        ),
      ),
    );
  }
}
