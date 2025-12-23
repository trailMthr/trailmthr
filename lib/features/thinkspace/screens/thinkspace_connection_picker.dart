import 'package:flutter/material.dart';

import '../data/thinkspace_repository.dart';
import '../models/think_node.dart';

class ConnectionPickerScreen extends StatefulWidget {
  final ThinkNode node;
  final ThinkSpaceRepository repository;

  const ConnectionPickerScreen({
    super.key,
    required this.node,
    required this.repository,
  });

  @override
  State<ConnectionPickerScreen> createState() =>
      _ConnectionPickerScreenState();
}

class _ConnectionPickerScreenState
    extends State<ConnectionPickerScreen> {
  List<ThinkNode> _all = [];
  List<String> _selected = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = [...widget.node.links];
    _load();
  }

  Future<void> _load() async {
    final all = await widget.repository.searchNodes(limit: 500);
    setState(() {
      _all = all.where((n) => n.id != widget.node.id).toList();
    });
  }

  Future<void> _save() async {
    final updated = widget.node.copyWith(links: _selected);
    await widget.repository.updateNode(updated);
    if (!mounted) return;
    Navigator.pop(context);
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
        title: const Text('Manage Connections'),
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
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final n = filtered[index];
                final isLinked = _selected.contains(n.id);
                return CheckboxListTile(
                  value: isLinked,
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
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        if (!_selected.contains(n.id)) {
                          _selected.add(n.id);
                        }
                      } else {
                        _selected.remove(n.id);
                      }
                    });
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
