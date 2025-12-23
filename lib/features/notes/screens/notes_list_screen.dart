import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import 'note_editor_screen.dart';

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final notes = notesProvider.notes;

        return Scaffold(
          backgroundColor: _trailBackground,
          appBar: AppBar(
            backgroundColor: _trailGreen,
            title: const Text(
              'Trail Notes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.eco, color: Colors.white),
                tooltip: 'Mushroom Surprise',
                onPressed: () {
                  final quotes = [
                    '“All who wander are not lost.” — Tolkien',
                    'Mushrooms: the quiet recyclers of the wild.',
                    'Take only memories, leave only footprints.',
                    'Hydrate early, hydrate often.',
                    'Every step writes a story.',
                  ];
                  final msg = quotes[Random().nextInt(quotes.length)];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ],
          ),

          // Body
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: _cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: notesProvider.setSearchQuery,
                ),
              ),

              Expanded(
                child: notesProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notes.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              return _NoteListItem(note: notes[index]);
                            },
                          ),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _accentColor,
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text(
              'New Note',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              final now = DateTime.now();
              final newNote = Note(
                title: '',
                content: '',
                createdAt: now,
                updatedAt: now,
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NoteEditorScreen(note: newNote),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.menu_book_rounded, size: 72, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tap “New Note” to capture your trail thoughts,\nbreadcrumbs, and memories.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ========== Note List Item Widget ==========

class _NoteListItem extends StatelessWidget {
  final Note note;
  const _NoteListItem({required this.note});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotesProvider>(context, listen: false);

    return Card(
      color: _cardColor,
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(note: note),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                note.pinned ? Icons.push_pin : Icons.menu_book_rounded,
                color: note.pinned ? _accentColor : _iconMuted,
              ),
              const SizedBox(width: 10),

              // Title + content preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isEmpty ? '(Untitled)' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      note.content.isEmpty
                          ? 'No content'
                          : note.content.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        if (note.reminderEnabled &&
                            note.reminderTime != null)
                          Row(
                            children: [
                              const Icon(Icons.alarm, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _format(note.reminderTime!),
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        Icon(
                          _visibilityIcon(note.visibility),
                          size: 14,
                          color: _iconMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  note.pinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                ),
                onPressed: () => provider.togglePinned(note),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _visibilityIcon(NoteVisibility v) {
    switch (v) {
      case NoteVisibility.private:
        return Icons.lock_outline;
      case NoteVisibility.public:
        return Icons.public;
      case NoteVisibility.anonymousPublic:
        return Icons.visibility_off;
    }
  }

  static String _format(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ========== Earth Tone Theme Colors ==========

const _trailBackground = Color(0xFFF4EFE6);
const _trailGreen = Color(0xFF4A6C4F);
const _cardColor = Color(0xFFE5D9C8);
const _accentColor = Color(0xFFB3743A);
const _iconMuted = Color(0xFF6A5F50);
