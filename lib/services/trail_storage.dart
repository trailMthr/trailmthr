import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/trail_record.dart';

class TrailStorage {
  static const _fileName = "trails.json";

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$_fileName");
  }

  static Future<List<TrailRecord>> loadTrails() async {
    try {
      final f = await _getFile();
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => TrailRecord.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTrail(TrailRecord trail) async {
    final trails = await loadTrails();
    trails.insert(0, trail); // newest first
    final f = await _getFile();
    await f.writeAsString(jsonEncode(trails.map((t) => t.toJson()).toList()));
  }

  static Future<void> deleteTrail(String id) async {
    final trails = await loadTrails();
    trails.removeWhere((t) => t.id == id);
    final f = await _getFile();
    await f.writeAsString(jsonEncode(trails.map((t) => t.toJson()).toList()));
  }

  static Future<void> clearAll() async {
    final f = await _getFile();
    if (await f.exists()) await f.delete();
  }
}
