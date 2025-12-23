import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/thought_provider.dart';
import '../models/thought_bubble.dart';
import 'bubble_view_screen.dart';

class BubbleGraphScreen extends StatelessWidget {
  const BubbleGraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThoughtProvider>();
    final roots = provider.rootBubbles;

    return Scaffold(
      appBar: AppBar(title: const Text("Thought Network")),
      body: ListView(
        children: roots.map((bubble) => _Node(bubble: bubble)).toList(),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  final ThoughtBubble bubble;

  const _Node({required this.bubble});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThoughtProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: _colorDot(bubble.color),
        title: Text(
          bubble.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        children: [
          // horizontal children preview chips
          if (bubble.children.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: bubble.children.map((id) {
                  final child = provider.getBubble(id);
                  if (child == null) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: _hex(child.color).withOpacity(.2),
                      label: Text(child.title),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BubbleViewScreen(id: child.id),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          ListTile(
            title: const Text("Open"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BubbleViewScreen(id: bubble.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _colorDot(String hex) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: _hex(hex),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _hex(String hex) =>
      Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
}
