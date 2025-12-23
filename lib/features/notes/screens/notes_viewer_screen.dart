import 'package:flutter/material.dart';

import '../../map/data/saved_place_db.dart';

class NotesViewerScreen extends StatefulWidget {
  const NotesViewerScreen({super.key});

  @override
  State<NotesViewerScreen> createState() => _NotesViewerScreenState();
}

class _NotesViewerScreenState extends State<NotesViewerScreen> {
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final rows = await SavedPlaceDb.instance.getAllNotes();

    setState(() {
      _notes = rows;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Notes"),
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Text("No notes yet."),
            )
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];

                final text = (note["text"] ?? "").toString();
                final createdAt =
                    DateTime.fromMillisecondsSinceEpoch(note["created_at"]);

                final preview = text.length > 60
                    ? "${text.substring(0, 60)}…"
                    : text;

                return ListTile(
                  title: Text(preview),
                  subtitle: Text(
                    createdAt.toLocal().toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  leading: const Icon(Icons.lightbulb_outline),
                  onTap: () {
                    _openNoteDetail(note);
                  },
                );
              },
            ),
    );
  }

  void _openNoteDetail(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Note"),
          content: SingleChildScrollView(
            child: Text(note["text"] ?? ""),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
