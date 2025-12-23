import 'package:flutter/material.dart';
import '../models/think_node.dart';
import '../data/thinkspace_repository.dart';
import '../screens/thinkspace_connection_picker.dart';
import '../screens/thinkspace_parent_picker.dart';

class EditThoughtPanel extends StatefulWidget {
  final ThinkNode node;
  final ThinkSpaceRepository repository;

  const EditThoughtPanel({
    super.key,
    required this.node,
    required this.repository,
  });

  @override
  State<EditThoughtPanel> createState() => _EditThoughtPanelState();
}

class _EditThoughtPanelState extends State<EditThoughtPanel> {
  late String lifecycle;
  late String functionType;

  @override
  void initState() {
    super.initState();
    lifecycle = widget.node.lifecycleState;
    functionType = widget.node.functionType;
  }

  Future<void> _save() async {
    final updated = widget.node.copyWith(
      lifecycleState: lifecycle,
      functionType: functionType,
    );
    await widget.repository.updateNode(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Edit Thought",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Lifecycle
          DropdownButtonFormField<String>(
            value: lifecycle,
            decoration: const InputDecoration(labelText: "Status"),
            items: [
              "idea",
              "concept",
              "thought",
              "brainstorm",
              "perspective",
              "archived",
            ].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toUpperCase()),
              );
            }).toList(),
            onChanged: (v) => setState(() => lifecycle = v!),
          ),

          const SizedBox(height: 16),

          // Function type
          DropdownButtonFormField<String>(
            value: functionType,
            decoration: const InputDecoration(labelText: "Function"),
            items: [
              "text",
              "todo",
              "reminder",
              "calendar",
              "goal",
              "drawing",
              "journal",
            ].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toUpperCase()),
              );
            }).toList(),
            onChanged: (v) => setState(() => functionType = v!),
          ),

          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text("Manage Connections"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConnectionPickerScreen(
                    node: widget.node,
                    repository: widget.repository,
                  ),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.account_tree_rounded),
            title: const Text("Change Parent"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ParentPickerScreen(
                    node: widget.node,
                    repository: widget.repository,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Text("Save Changes"),
          )
        ],
      ),
    );
  }
}
