import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../map/data/saved_place_db.dart';

class QuickNoteScreen extends StatefulWidget {
  final LatLng position;

  const QuickNoteScreen({
    super.key,
    required this.position,
  });

  @override
  State<QuickNoteScreen> createState() => _QuickNoteScreenState();
}

class _QuickNoteScreenState extends State<QuickNoteScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quick Note")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Save Note"),
              onPressed: () async {
                if (_ctrl.text.trim().isEmpty) return;

                final note = {
                  "id": DateTime.now().millisecondsSinceEpoch.toString(),
                  "text": _ctrl.text.trim(),
                  "lat": widget.position.latitude,
                  "lng": widget.position.longitude,
                  "created_at": DateTime.now().millisecondsSinceEpoch,
                };

                await SavedPlaceDb.instance.insertNote(note);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
