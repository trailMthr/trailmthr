import 'dart:convert';
import 'package:flutter/material.dart';

class MarkerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> marker;
  final bool canEdit;

  const MarkerDetailsScreen({
    super.key,
    required this.marker,
    required this.canEdit,
  });

  @override
  State<MarkerDetailsScreen> createState() => _MarkerDetailsScreenState();
}

class _MarkerDetailsScreenState extends State<MarkerDetailsScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _reviewCtrl;

  late String _type;
  double _myRating = 0;

  late List<Map<String, dynamic>> _reviews;

  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(text: widget.marker["name"]);
    _notesCtrl = TextEditingController(text: widget.marker["notes"]);
    _reviewCtrl = TextEditingController();
    _type = widget.marker["type"];

    final rawReviews = widget.marker["reviews_json"];
    if (rawReviews != null && rawReviews.toString().isNotEmpty) {
      final decoded = jsonDecode(rawReviews);
      _reviews = List<Map<String, dynamic>>.from(decoded);
    } else {
      _reviews = [];
    }
  }

  double _calculateAverage() {
    if (_reviews.isEmpty) return _myRating;
    final sum = _reviews.fold<double>(
      0,
      (t, r) => t + (r["rating"] as num).toDouble(),
    );
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final avg = _calculateAverage();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Marker Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Marker flagged")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ TITLE
            TextField(
              controller: _titleCtrl,
              readOnly: !widget.canEdit,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            const SizedBox(height: 12),

            // ✅ TYPE
            DropdownButtonFormField<String>(
              value: _type,
              onChanged: widget.canEdit
                  ? (v) => setState(() => _type = v!)
                  : null,
              items: const [
                DropdownMenuItem(value: "camp", child: Text("Camp")),
                DropdownMenuItem(value: "water", child: Text("Water")),
                DropdownMenuItem(value: "view", child: Text("View")),
                DropdownMenuItem(value: "hazard", child: Text("Hazard")),
                DropdownMenuItem(value: "whisper", child: Text("Whisper")),
                DropdownMenuItem(value: "poi", child: Text("POI")),
              ],
              decoration: const InputDecoration(labelText: "Type"),
            ),

            const SizedBox(height: 12),

            // ✅ NOTES
            TextField(
              controller: _notesCtrl,
              readOnly: !widget.canEdit,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Notes"),
            ),

            const Divider(height: 32),

            // ✅ RATING DISPLAY
            Text(
              "Average Rating: ${avg.toStringAsFixed(1)} ★",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // ✅ USER STAR INPUT
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  icon: Icon(
                    star <= _myRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() => _myRating = star.toDouble());
                  },
                );
              }),
            ),

            // ✅ REVIEW INPUT
            TextField(
              controller: _reviewCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: "Write a quick review (optional)…",
              ),
            ),

            const SizedBox(height: 8),

            // ✅ SUBMIT REVIEW
            ElevatedButton(
              onPressed: () {
                if (_myRating == 0) return;

                _reviews.add({
                  "rating": _myRating,
                  "text": _reviewCtrl.text,
                  "time": DateTime.now().millisecondsSinceEpoch,
                });

                _reviewCtrl.clear();
                setState(() {});
              },
              child: const Text("Submit Review"),
            ),

            const Divider(height: 24),

            // ✅ REVIEW LIST
            const Text(
              "Reviews",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ..._reviews.map((r) => ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text("${r["rating"]} ★"),
                  subtitle: Text(r["text"] ?? ""),
                )),

            const SizedBox(height: 24),

            // ✅ SAVE CHANGES
            if (widget.canEdit)
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                onPressed: () {
                  Navigator.pop(context, {
                    ...widget.marker,
                    "name": _titleCtrl.text,
                    "type": _type,
                    "notes": _notesCtrl.text,
                    "rating_avg": _calculateAverage(),
                    "reviews_json": jsonEncode(_reviews),
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
