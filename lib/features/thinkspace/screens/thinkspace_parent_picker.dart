import 'package:flutter/material.dart';

import '../data/thinkspace_repository.dart';
import '../models/think_node.dart';
import 'think_node_detail_screen.dart';

class ParentPickerScreen extends StatefulWidget {
  final ThinkNode node;
  final ThinkSpaceRepository repository;

  const ParentPickerScreen({
    super.key,
    required this.node,
    required this.repository,
  });

  @override
  State<ParentPickerScreen> createState() => _ParentPickerScreenState();
}

class _ParentPickerScreenState extends State<ParentPickerScreen> {
  List<ThinkNode> _all = [];
  String _query = '';
  String? _selectedParentId; // null = root

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.node.parentId;
    _load();
  }

  Future<void> _load() async {
    // For now, just load a big list; later we can paginate if needed.
    final all = await widget.repository.searchNodes(limit: 500);
    setState(() {
      _all = all.where((n) => n.id != widget.node.id).toList();
    });
  }

  Future<void> _save() async {
    final updated = widget.node.copyWith(parentId: _selectedParentId);
    await widget.repository.updateNode(updated);
    if (!mounted) return;
    Navigator.pop(context); // close picker
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _all.where((n) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Parent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search thoughts…',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() => _query = v);
              },
            ),
          ),
          ListTile(
            leading: Radio<String?>(
              value: null,
              groupValue: _selectedParentId,
              onChanged: (v) {
                setState(() => _selectedParentId = v);
              },
            ),
            title: const Text('Make Root Thought'),
            subtitle: const Text('No parent'),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final n = filtered[index];
                return RadioListTile<String?>(
                  value: n.id,
                  groupValue: _selectedParentId,
                  title: Text(
                    n.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    n.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onChanged: (v) {
                    setState(() => _selectedParentId = v);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
