// lib/features/thinkspace/widgets/quicknote_sheet.dart
import 'package:flutter/material.dart';

import '../data/thinkspace_repository.dart';

class QuickNoteSheet extends StatefulWidget {
  final ThinkSpaceRepository repository;

  /// Optional links to context
  final String? locationId; // marker id if known
  final String? activityId; // current activity id if recording

  const QuickNoteSheet({
    super.key,
    required this.repository,
    this.locationId,
    this.activityId,
  });

  @override
  State<QuickNoteSheet> createState() => _QuickNoteSheetState();
}

class _QuickNoteSheetState extends State<QuickNoteSheet> {
  final TextEditingController _ctrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final text = _ctrl.text.trim();
      if (text.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      await widget.repository.createNode(
        type: 'quicknote',
        content: text,
        tags: const ['quicknote'],
        locationId: widget.locationId,
        activityId: widget.activityId,
      );

      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick note',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: 'Drop a thought…',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
