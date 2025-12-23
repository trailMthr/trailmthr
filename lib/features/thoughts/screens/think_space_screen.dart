import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/thought_provider.dart';

class ThinkSpaceScreen extends StatefulWidget {
  const ThinkSpaceScreen({super.key});

  @override
  State<ThinkSpaceScreen> createState() => _ThinkSpaceScreenState();
}

class _ThinkSpaceScreenState extends State<ThinkSpaceScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _selectedColor = "#888888";

  final List<String> _starterPrompts = [
    "To-do list",
    "Idea I'm exploring",
    "A problem I'm solving",
    "My current mood",
    "A plan for the week",
    "Something I'm avoiding",
    "A dream or vision",
  ];

  String? _selectedPrompt;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;

    Provider.of<ThoughtProvider>(context, listen: false).addRootBubble(
      _titleCtrl.text.trim(),
      _bodyCtrl.text.trim(),
      color: _selectedColor,
    );

    _titleCtrl.clear();
    _bodyCtrl.clear();
    _selectedPrompt = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Thought saved")),
    );
  }

  void _applyPrompt() {
    if (_selectedPrompt == null) return;
    _titleCtrl.text = _selectedPrompt!;
    _bodyCtrl.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Think Space")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: "Main Idea"),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: "Write freely...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedPrompt,
              hint: const Text("Starter prompt (optional)"),
              items: _starterPrompts
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedPrompt = v);
                _applyPrompt();
              },
            ),
            const SizedBox(height: 12),

            // COLOR PICKER
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _colorOptions().map((hex) {
                  Color color = _hex(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == hex
                              ? Colors.black87
                              : Colors.black26,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _save,
              child: const Text("Save Thought"),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _colorOptions() => [
        "#FF6B6B",
        "#FFA502",
        "#2ED573",
        "#1E90FF",
        "#B53471",
        "#596275",
        "#D980FA",
        "#ECCC68",
        "#888888",
      ];

  Color _hex(String hex) =>
      Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
}
