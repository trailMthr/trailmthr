import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:uuid/uuid.dart';

import '../data/saved_place_db.dart';
import 'package:trailmthr_test2/core/trail_objects/trail_object.dart';
import 'package:trailmthr_test2/features/thinkspace/data/thinkspace_repository.dart';

class MarkerCreatorScreen extends StatefulWidget {
  final ll.LatLng position;
  final ThinkSpaceRepository thinkRepo;

  const MarkerCreatorScreen({
    super.key,
    required this.position,
    required this.thinkRepo,
  });

  @override
  State<MarkerCreatorScreen> createState() => _MarkerCreatorScreenState();
}

class _MarkerCreatorScreenState extends State<MarkerCreatorScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _type = "camp";
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_saving) return;
    _saving = true;

    final now = DateTime.now();
    final id = const Uuid().v4();

    // ------------------------------------------------------------
    // 1️⃣ SAVE TO MAP / UI DATABASE
    // ------------------------------------------------------------
    final place = {
      "id": id,
      "name": _titleCtrl.text.isNotEmpty ? _titleCtrl.text : "Untitled",
      "type": _type,
      "notes": _notesCtrl.text,
      "lat": widget.position.latitude,
      "lng": widget.position.longitude,
      "created_at": now.millisecondsSinceEpoch,
      "owner_id": "local",
      "visibility": "private",
      "locked": 0,
    };

    await SavedPlaceDb.instance.upsertPlace(place);

    // ------------------------------------------------------------
    // 2️⃣ EMIT TRAIL OBJECT (SAME DB AS THINKSPACE)
    // ------------------------------------------------------------
    final trailObject = TrailObject(
      id: id,
      type: 'marker',
      timestamp: now,
      lat: widget.position.latitude,
      lng: widget.position.longitude,
      source: 'user',
      payload: {
        "marker_id": id,
        "title": place["name"],
        "marker_type": _type,
        "notes": _notesCtrl.text,
      },
    );

    await widget.thinkRepo.insertTrailObject(trailObject);
//
await widget.thinkRepo.createNode(
  type: 'marker',
  content: place["name"] as String,
  locationId: id,
  lifecycleState: 'idea',
);

    // ------------------------------------------------------------
    // 3️⃣ CLOSE SHEET (SAFE)
    // ------------------------------------------------------------
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Marker"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: "Type"),
              items: const [
                DropdownMenuItem(value: "camp", child: Text("Camp")),
                DropdownMenuItem(value: "water", child: Text("Water")),
                DropdownMenuItem(value: "view", child: Text("View")),
                DropdownMenuItem(value: "hazard", child: Text("Hazard")),
                DropdownMenuItem(value: "poi", child: Text("Point of Interest")),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Notes"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : _onSave,
              child: const Text("Save Marker"),
            ),
          ],
        ),
      ),
    );
  }
}
