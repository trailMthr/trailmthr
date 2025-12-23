import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/note_model.dart';

class NotesStorage {
  static const _fileName = "notes.json";

  // ----------------------------
  // LOAD NOTES
  // ----------------------------
  static Future<List<Note>> loadNotes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/$_fileName");

      if (!await file.exists()) {
        return [];
      }

      final text = await file.readAsString();
      if (text.isEmpty) return [];

      final data = jsonDecode(text) as List<dynamic>;
      return data.map((j) => Note.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  // ----------------------------
  // SAVE NOTES
  // ----------------------------
  static Future<void> saveNotes(List<Note> notes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$_fileName");

    final data = notes.map((n) => n.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }
}
