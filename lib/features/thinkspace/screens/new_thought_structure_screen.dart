import 'package:flutter/material.dart';

import '../data/thinkspace_repository.dart';
import 'new_thought_function_screen.dart';

class NewThoughtStructureScreen extends StatefulWidget {
  final ThinkSpaceRepository repository;
  final String? parentId;

  const NewThoughtStructureScreen({
    super.key,
    required this.repository,
    this.parentId,
  });


  @override
  State<NewThoughtStructureScreen> createState() =>
      _NewThoughtStructureScreenState();
}

class _NewThoughtStructureScreenState extends State<NewThoughtStructureScreen> {
  String? _selectedStructure;

  final List<_StructureOption> _options = const [
    _StructureOption(
      id: 'idea',
      label: 'Idea',
      description: 'A small seed or simple thought.',
      icon: Icons.lightbulb_outline_rounded,
    ),
    _StructureOption(
      id: 'concept',
      label: 'Concept',
      description: 'A defined idea, the new home for quick captures.',
      icon: Icons.category_rounded,
    ),
    _StructureOption(
      id: 'thought',
      label: 'Thought',
      description: 'A deeper exploration with more detail.',
      icon: Icons.psychology_rounded,
    ),
    _StructureOption(
      id: 'brainstorm',
      label: 'Brainstorm',
      description: 'Branching ideas and divergent thinking.',
      icon: Icons.bubble_chart_rounded,
    ),
    _StructureOption(
      id: 'perspective',
      label: 'Perspective',
      description: 'High-level worldview or core belief.',
      icon: Icons.auto_stories_rounded,
    ),
  ];

  void _onNext() {
    if (_selectedStructure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a structure to continue.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
builder: (_) => NewThoughtFunctionScreen(
  repository: widget.repository,
  structureId: _selectedStructure!,
  parentId: widget.parentId,
),

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Thought • Structure'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What kind of thought is this?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start by choosing the mental structure. You can always refine this later as it grows.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final opt = _options[index];
                  final selected = opt.id == _selectedStructure;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedStructure = opt.id);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.12)
                            : Theme.of(context).colorScheme.surfaceVariant,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(opt.icon, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _onNext,
              child: const Text('Next: Choose Function'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StructureOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const _StructureOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}
