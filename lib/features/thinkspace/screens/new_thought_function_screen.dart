import 'package:flutter/material.dart';

import '../data/thinkspace_repository.dart';
import 'think_node_detail_screen.dart';

class NewThoughtFunctionScreen extends StatelessWidget {
  final ThinkSpaceRepository repository;
  final String structureId; // idea | concept | thought | brainstorm | perspective
final String? parentId;

  const NewThoughtFunctionScreen({
    super.key,
    required this.repository,
    required this.structureId,
    this.parentId,
  });

  @override
  Widget build(BuildContext context) {
    final options = <_FunctionOption>[
      const _FunctionOption(
        id: 'text',
        label: 'Text',
        description: 'Write freely in a blank page.',
        icon: Icons.notes_rounded,
      ),
      const _FunctionOption(
        id: 'todo',
        label: 'To-Do List',
        description: 'Checklist for tasks and steps.',
        icon: Icons.checklist_rounded,
      ),
      const _FunctionOption(
        id: 'reminder',
        label: 'Reminder',
        description: 'Set a nudge for later.',
        icon: Icons.alarm_rounded,
      ),
      const _FunctionOption(
        id: 'calendar',
        label: 'Calendar Item',
        description: 'Schedule it on your time map.',
        icon: Icons.calendar_today_rounded,
      ),
      const _FunctionOption(
        id: 'drawing',
        label: 'Drawing Pad',
        description: 'Sketch or doodle the idea.',
        icon: Icons.brush_rounded,
      ),
      const _FunctionOption(
        id: 'template',
        label: 'Template',
        description: 'Start from a guided structure.',
        icon: Icons.dashboard_customize_rounded,
      ),
    ];

    Future<void> handleTap(_FunctionOption opt) async {
      // For v1: everything goes to the same text editor,
      // but we store the chosen functionType so we can
      // show different UIs later.
      final scaffold = ScaffoldMessenger.of(context);

      try {
final newNode = await repository.createNode(
  parentId: parentId,
  type: structureId,           // "idea", "concept", ...
  content: '',
  lifecycleState: structureId, // same for now; we can evolve rules later
  functionType: opt.id,        // "text", "todo", "reminder", etc.
);


        // Navigate to detail editor
        // (later we can branch here based on functionType)
        // ignore: use_build_context_synchronously
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ThinkNodeDetailScreen(
              repository: repository,
              nodeId: newNode.id,
            ),
          ),
        );

        // After returning, just pop this screen as well to go back home
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Failed to create thought: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Thought • Function'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How do you want to work with this thought?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pick the format that fits this moment. You can always link or duplicate later.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
                children: options.map((opt) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => handleTap(opt),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color:
                            Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(opt.icon, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            opt.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FunctionOption {
  final String id;          // "text", "todo", "reminder", ...
  final String label;
  final String description;
  final IconData icon;

  const _FunctionOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}
