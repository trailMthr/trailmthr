import 'package:flutter/material.dart';
import '../models/think_node.dart';

class RelationshipSection extends StatelessWidget {
  final String title;
  final List<ThinkNode> items;
  final VoidCallback? onTapAdd;
  final void Function(ThinkNode)? onOpen;

  const RelationshipSection({
    super.key,
    required this.title,
    required this.items,
    this.onTapAdd,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onTapAdd != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: onTapAdd,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                "No ${title.toLowerCase()}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ...items.map(
              (node) => InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onOpen?.call(node),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          node.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
