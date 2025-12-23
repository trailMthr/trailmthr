import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/thought_provider.dart';

class DeleteBubbleDialog extends StatelessWidget {
  final String bubbleId;

  const DeleteBubbleDialog({super.key, required this.bubbleId});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ThoughtProvider>();

    return AlertDialog(
      title: const Text("Delete Thought"),
      content: const Text("Choose how to handle connected thoughts:"),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.arrow_upward),
          label: const Text("Move children up"),
          onPressed: () {
            provider.deleteBubble(
              bubbleId,
              mode: DeleteMode.moveChildrenToParent,
            );
            Navigator.pop(context);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.call_split),
          label: const Text("Detach to root"),
          onPressed: () {
            provider.deleteBubble(
              bubbleId,
              mode: DeleteMode.detachChildrenToRoot,
            );
            Navigator.pop(context);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
          label: const Text(
            "Delete all",
            style: TextStyle(color: Colors.redAccent),
          ),
          onPressed: () {
            provider.deleteBubble(
              bubbleId,
              mode: DeleteMode.deleteSubtree,
            );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
