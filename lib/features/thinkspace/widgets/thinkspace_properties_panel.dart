import 'package:flutter/material.dart';
import '../data/thinkspace_repository.dart';
import '../models/think_node.dart';

class ThinkSpacePropertiesPanel extends StatefulWidget {
  final ThinkSpaceRepository repository;
  final ThinkNode node;

  const ThinkSpacePropertiesPanel({
    super.key,
    required this.repository,
    required this.node,
  });

  @override
  State<ThinkSpacePropertiesPanel> createState() =>
      _ThinkSpacePropertiesPanelState();
}

class _ThinkSpacePropertiesPanelState
    extends State<ThinkSpacePropertiesPanel> {
  late String lifecycle;
  late String functionType;
  late double importance;
  late TextEditingController tagCtrl;
  bool _saving = false;
  bool _suggesting = false;

  @override
  void initState() {
    super.initState();
    lifecycle = widget.node.lifecycleState;
    functionType = widget.node.functionType;
    importance = widget.node.importance;
    
    tagCtrl = TextEditingController(
  text: widget.node.tags.join(", "),
);

  }

  @override
  void dispose() {
    tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tagsList = tagCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final updated = widget.node.copyWith(
      lifecycleState: lifecycle,
      functionType: functionType,
      importance: importance,
      tags: tagsList,
      updated: DateTime.now(),
    );

    setState(() => _saving = true);
    await widget.repository.updateNode(updated);
    setState(() => _saving = false);

    if (!mounted) return;
    Navigator.pop(context);
  }

  /// Basic “AI-ish” heuristics for now: inspect content and derive
  /// lifecycle, function type, importance and tag suggestions.
  void _suggestFromContent() {
    final content = widget.node.content.toLowerCase();
    if (content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No content to analyze yet.")),
      );
      return;
    }

    setState(() => _suggesting = true);

    // --- LIFECYCLE HEURISTIC ---
    String newLifecycle = lifecycle;
    final lineCount = content.split('\n').length;

    final hasBullet =
        content.contains('- ') || content.contains('* ') || content.contains('•');
    final hasQuestion =
        content.contains('?') || content.contains('what if') || content.contains('how ');

    if (hasBullet && lineCount >= 5) {
      newLifecycle = 'brainstorm';
    } else if (hasQuestion) {
      newLifecycle = 'idea';
    } else if (lineCount > 8) {
      newLifecycle = 'thought';
    } else {
      newLifecycle = 'concept';
    }

    // --- FUNCTION TYPE HEURISTIC ---
    String newFunctionType = functionType;

    final hasTodoMarkers = content.contains('[ ]') ||
        content.contains('todo') ||
        content.contains('to do') ||
        content.contains('task');

    final hasDateLike = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b')
            .hasMatch(content) ||
        content.contains('tomorrow') ||
        content.contains('next week') ||
        content.contains('schedule');

    final hasGoalWords =
        content.contains('goal') || content.contains('target') || content.contains('aim');

    final hasMoodWords = content.contains('feel') ||
        content.contains('today was') ||
        content.contains('grateful') ||
        content.contains('journal');

    if (hasTodoMarkers) {
      newFunctionType = 'todo';
    } else if (hasDateLike) {
      newFunctionType = 'calendar';
    } else if (hasGoalWords) {
      newFunctionType = 'goal';
    } else if (hasMoodWords) {
      newFunctionType = 'journal';
    } else {
      newFunctionType = 'text';
    }

    // --- IMPORTANCE HEURISTIC ---
    // Longer, denser notes and those with TODO/goal/date get higher importance.
    double newImportance = importance;
    final length = content.length;
    newImportance = (length / 1000.0).clamp(0.1, 1.0);
    if (hasGoalWords || hasTodoMarkers || hasDateLike) {
      newImportance = (newImportance + 0.3).clamp(0.0, 1.0);
    }

    // --- TAG SUGGESTIONS ---
    final words = content
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toList();

    const stopwords = {
      'this',
      'that',
      'with',
      'from',
      'about',
      'there',
      'their',
      'have',
      'would',
      'could',
      'should',
      'being',
      'will',
      'just',
      'some',
      'into',
      'over',
      'under',
      'then',
      'than',
      'also',
      'really',
      'very',
      'been',
      'were',
      'them',
      'they',
      'what',
      'when',
      'where',
      'your',
      'mine',
      'ours',
      'hers',
      'his',
      'here',
      'such',
    };

    final freq = <String, int>{};
    for (final w in words) {
      if (stopwords.contains(w)) continue;
      freq[w] = (freq[w] ?? 0) + 1;
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final suggestedTags = sorted
        .take(6)
        .map((e) => e.key)
        .toSet() // dedupe
        .toList();

    final existingTags = tagCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final mergedTags = [
      ...existingTags,
      ...suggestedTags.where((t) => !existingTags.contains(t)),
    ];

    setState(() {
      lifecycle = newLifecycle;
      functionType = newFunctionType;
      importance = newImportance;
      tagCtrl.text = mergedTags.join(', ');
      _suggesting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Suggestions applied.")),
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
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Handle bar
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
                Center(
                  child: Text(
                    "Thought Properties",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _suggesting ? null : _suggestFromContent,
                    icon: _suggesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: const Text("Suggest from content"),
                  ),
                ),
                const SizedBox(height: 8),

                // -----------------------------
                // LIFECYCLE
                // -----------------------------
                _buildCard(
                  title: "Status",
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      "idea",
                      "concept",
                      "thought",
                      "brainstorm",
                      "perspective",
                      "archived",
                    ].map((type) {
                      final selected = (type == lifecycle);
                      return ChoiceChip(
                        label: Text(type.toUpperCase()),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => lifecycle = type);
                        },
                      );
                    }).toList(),
                  ),
                ),

                // -----------------------------
                // FUNCTION TYPE
                // -----------------------------
                _buildCard(
                  title: "Function",
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      "text",
                      "todo",
                      "reminder",
                      "calendar",
                      "goal",
                      "drawing",
                      "journal",
                    ].map((type) {
                      final selected = (type == functionType);
                      return ChoiceChip(
                        label: Text(type.toUpperCase()),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => functionType = type);
                        },
                      );
                    }).toList(),
                  ),
                ),

                // -----------------------------
                // IMPORTANCE
                // -----------------------------
                _buildCard(
                  title: "Importance",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: importance,
                        min: 0,
                        max: 1,
                        divisions: 100,
                        label: importance.toStringAsFixed(2),
                        onChanged: (v) {
                          setState(() => importance = v);
                        },
                      ),
                    ],
                  ),
                ),

                // -----------------------------
                // TAGS
                // -----------------------------
                _buildCard(
                  title: "Tags",
                  child: TextField(
                    controller: tagCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "comma, separated, tags",
                    ),
                  ),
                ),

                // -----------------------------
                // METADATA
                // -----------------------------
                _buildCard(
                  title: "Metadata",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Created: ${node.created}"),
                      const SizedBox(height: 4),
                      Text("Updated: ${node.updated}"),
                      const SizedBox(height: 4),
                      Text("Parent ID: ${node.parentId ?? 'None'}"),
                      const SizedBox(height: 4),
                      Text("Linked Thoughts: ${node.links.length}"),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // SAVE BUTTON
                Center(
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text("Save Changes"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
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
