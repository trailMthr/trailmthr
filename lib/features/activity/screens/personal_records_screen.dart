// lib/features/activity/screens/personal_records_screen.dart
import 'package:flutter/material.dart';

import '../data/activity_db.dart';
import '../models/activity_models.dart';

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  State<PersonalRecordsScreen> createState() => _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends State<PersonalRecordsScreen> {
  bool _loading = true;
  List<ActivitySession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await ActivityDb.instance.getAllSessions();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prs = _computePrs(_sessions);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Records"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text("No activities yet."))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _prTile(
                      "Longest distance",
                      prs.longestDistance,
                    ),
                    _prTile(
                      "Longest duration",
                      prs.longestDuration,
                    ),
                    _prTile(
                      "Fastest pace (for ≥ 1 km)",
                      prs.fastestPace,
                    ),
                  ],
                ),
    );
  }

  Widget _prTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  _PrData _computePrs(List<ActivitySession> sessions) {
    if (sessions.isEmpty) {
      return _PrData(
        longestDistance: "--",
        longestDuration: "--",
        fastestPace: "--",
      );
    }

    ActivitySession? longestDist;
    ActivitySession? longestDur;
    ActivitySession? bestPace;

    for (final s in sessions) {
      if (longestDist == null ||
          s.distanceMeters > longestDist!.distanceMeters) {
        longestDist = s;
      }
      if (longestDur == null || s.duration > longestDur!.duration) {
        longestDur = s;
      }
      if (s.distanceKm >= 1.0) {
        if (bestPace == null ||
            s.paceSecondsPerKm < bestPace!.paceSecondsPerKm) {
          bestPace = s;
        }
      }
    }

    String formatDuration(Duration d) {
      final h = d.inHours.toString().padLeft(2, '0');
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return "$h:$m:$s";
    }

    String formatPace(ActivitySession? s) {
      if (s == null || s.distanceKm <= 0) return "--";
      final secPerKm = s.paceSecondsPerKm;
      final min = (secPerKm ~/ 60);
      final sec = (secPerKm % 60).round();
      return "$min:${sec.toString().padLeft(2, '0')} /km";
    }

    return _PrData(
      longestDistance: longestDist == null
          ? "--"
          : "${longestDist!.distanceKm.toStringAsFixed(2)} km",
      longestDuration:
          longestDur == null ? "--" : formatDuration(longestDur!.duration),
      fastestPace: formatPace(bestPace),
    );
  }
}

class _PrData {
  final String longestDistance;
  final String longestDuration;
  final String fastestPace;

  _PrData({
    required this.longestDistance,
    required this.longestDuration,
    required this.fastestPace,
  });
}
