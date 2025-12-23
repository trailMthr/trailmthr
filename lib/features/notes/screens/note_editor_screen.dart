import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note note;
  const NoteEditorScreen({super.key, required this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late Note _editingNote;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();

    _editingNote = widget.note;

    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);

    final now = DateTime.now();

    _editingNote = _editingNote.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      updatedAt: now,
      createdAt: _editingNote.id == null ? now : _editingNote.createdAt,
    );

    await provider.addOrUpdateNote(_editingNote);

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteNote() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);

    if (_editingNote.id != null) {
      await provider.deleteNote(_editingNote);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleReminder() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);

    // If it's off, turn it on with default 1hr from now
    if (!_editingNote.reminderEnabled) {
      final now = DateTime.now();
      final defaultTime = now.add(const Duration(hours: 1));

      _editingNote = _editingNote.copyWith(
        reminderEnabled: true,
        reminderTime: defaultTime,
      );

      await provider.updateReminder(
        _editingNote,
        enabled: true,
        reminderTime: defaultTime,
      );

      setState(() {});
      return;
    }

    // If it's on, let the user pick a datetime
    final current = _editingNote.reminderTime ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (pickedTime == null) return;

    final chosen = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    _editingNote = _editingNote.copyWith(
      reminderEnabled: true,
      reminderTime: chosen,
    );

    await provider.updateReminder(
      _editingNote,
      enabled: true,
      reminderTime: chosen,
    );

    setState(() {});
  }

  Future<void> _clearReminder() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);

    _editingNote = _editingNote.copyWith(
      reminderEnabled: false,
      reminderTime: null,
    );

    await provider.updateReminder(
      _editingNote,
      enabled: false,
      reminderTime: null,
    );

    setState(() {});
  }

  Widget _buildVisibilityDropdown() {
    return DropdownButton<NoteVisibility>(
      value: _editingNote.visibility,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(
          value: NoteVisibility.private,
          child: Text('Private'),
        ),
        DropdownMenuItem(
          value: NoteVisibility.public,
          child: Text('Public'),
        ),
        DropdownMenuItem(
          value: NoteVisibility.anonymousPublic,
          child: Text('Anon'),
        ),
      ],
      onChanged: (value) async {
        if (value == null) return;

        final provider = Provider.of<NotesProvider>(context, listen: false);

        _editingNote = _editingNote.copyWith(visibility: value);

        await provider.updateVisibility(_editingNote, value);

        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _editingNote.id == null;

    return Scaffold(
      backgroundColor: _trailBackground,
      appBar: AppBar(
        backgroundColor: _trailGreen,
        title: Text(isNew ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteNote,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveAndExit,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // TITLE
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title (optional)',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(),

            // CONTENT
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Write your trail notes...',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 8),

            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Reminder button
          IconButton(
            icon: Icon(
              _editingNote.reminderEnabled
                  ? Icons.alarm_on
                  : Icons.alarm_add,
            ),
            onPressed: _toggleReminder,
          ),

          // Reminder time display
          if (_editingNote.reminderEnabled &&
              _editingNote.reminderTime != null)
            Expanded(
              child: Text(
                'Reminder: ${_formatDate(_editingNote.reminderTime!)}',
                style: const TextStyle(fontSize: 12),
              ),
            )
          else
            const Expanded(
              child: Text(
                'Add reminder',
                style: TextStyle(fontSize: 12),
              ),
            ),

          if (_editingNote.reminderEnabled)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearReminder,
            ),

          const SizedBox(width: 12),

          // Visibility dropdown
          _buildVisibilityDropdown(),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// Earth-tone colors
const _trailBackground = Color(0xFFF4EFE6);
const _trailGreen = Color(0xFF4A6C4F);
const _cardColor = Color(0xFFE5D9C8);
