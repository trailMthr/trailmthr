import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/thought_provider.dart';
import '../models/thought_bubble.dart';
import '../widgets/delete_bubble_dialog.dart';

class BubbleViewScreen extends StatefulWidget {
  final String id;

  const BubbleViewScreen({super.key, required this.id});

  @override
  State<BubbleViewScreen> createState() => _BubbleViewScreenState();
}

class _BubbleViewScreenState extends State<BubbleViewScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThoughtProvider>();
    final bubble = provider.getBubble(widget.id);

    if (bubble == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Not found")),
        body: const Center(child: Text("Thought no longer exists")),
      );
    }

    final children = bubble.children
        .map((id) => provider.getBubble(id))
        .where((b) => b != null)
        .cast<ThoughtBubble>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(bubble.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editBubble(context, provider, bubble),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, bubble),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addChild(context, provider, bubble),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // MAIN CARD
            Card(
              color: _hex(bubble.color).withOpacity(.15),
              elevation: 1,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bubble.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (bubble.body.isNotEmpty)
                      Text(bubble.body,
                          style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            const Text("Connected thoughts",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Expanded(
              child: children.isEmpty
                  ? const Center(child: Text("No connections yet."))
                  : ReorderableListView.builder(
                      itemCount: children.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = children.removeAt(oldIndex);
                          children.insert(newIndex, item);
                          provider.reorderChildren(
                              bubble.id, children.map((e) => e.id).toList());
                        });
                      },
                      itemBuilder: (_, i) {
                        final child = children[i];
                        return ListTile(
                          key: ValueKey(child.id),
                          leading: _dot(child.color),
                          title: Text(
                            child.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.drag_handle),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BubbleViewScreen(id: child.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _dot(String hex) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: _hex(hex),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _hex(String h) =>
      Color(int.parse(h.substring(1), radix: 16) + 0xFF000000);

  void _addChild(BuildContext context, ThoughtProvider provider,
      ThoughtBubble bubble) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Connected Thought"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Details"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final t = titleCtrl.text.trim();
              final b = bodyCtrl.text.trim();
              provider.addChildBubble(bubble.id, t, b);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _editBubble(
      BuildContext context, ThoughtProvider provider, ThoughtBubble bubble) {
    final titleCtrl = TextEditingController(text: bubble.title);
    final bodyCtrl = TextEditingController(text: bubble.body);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Thought"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Details"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                provider.updateBubble(
                    bubble.id, titleCtrl.text.trim(), bodyCtrl.text.trim());
                Navigator.pop(context);
              },
              child: const Text("Save")),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ThoughtBubble bubble) {
    showDialog(
      context: context,
      builder: (_) => DeleteBubbleDialog(bubbleId: bubble.id),
    ).then((_) {
      final provider = context.read<ThoughtProvider>();
      if (provider.getBubble(bubble.id) == null) {
        Navigator.pop(context);
      }
    });
  }
}
