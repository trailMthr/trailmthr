import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trail.dart';
import '../../../services/trails_repository.dart';
import '../../../navigation/app_state.dart';

// NEW — required for opening the viewer screen
import 'activity_viewer.dart';

class TrailHistoryScreen extends StatefulWidget {
  const TrailHistoryScreen({super.key});

  @override
  State<TrailHistoryScreen> createState() => _TrailHistoryScreenState();
}

class _TrailHistoryScreenState extends State<TrailHistoryScreen> {
  List<Trail> _trails = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await TrailsRepository.instance.getAllTrails();
    setState(() {
      _trails = data;
      _loading = false;
    });
  }

  String _fmtDate(DateTime dt) =>
      "${dt.month}/${dt.day}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";

  String _fmtDist(double m) =>
      m < 1000 ? "${m.toStringAsFixed(0)} m" : "${(m / 1000).toStringAsFixed(2)} km";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Past Activities"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await TrailsRepository.instance.clearAll();
              await _load();
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trails.isEmpty
              ? const Center(child: Text("No saved activities yet."))
              : ListView.builder(
                  itemCount: _trails.length,
                  itemBuilder: (_, i) {
                    final t = _trails[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          t.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "${_fmtDate(t.startTime)}  •  ${_fmtDist(t.distanceMeters)}",
                        ),

                        // OPEN DEDICATED ACTIVITY VIEWER
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityViewer(activity: t),
                            ),
                          );
                        },

                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == "delete") {
                              await TrailsRepository.instance.deleteTrail(t.id);
                              await _load();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: "delete",
                              child: Text("Delete"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
