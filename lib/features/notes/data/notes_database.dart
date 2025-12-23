import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note_model.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._internal();
  factory NotesDatabase() => instance;
  NotesDatabase._internal();

  Database? _database;

  Future<Database> _initDb() async {
  final dir = await getApplicationDocumentsDirectory();

  // Create structured folder path:
  final notesDir = Directory('${dir.path}/trailmthr/notes');

  // Make sure the folder exists
  if (!await notesDir.exists()) {
    await notesDir.create(recursive: true);
  }

  final path = join(notesDir.path, 'trailmthr_notes.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate: _onCreate,
  );
}


  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        reminder_enabled INTEGER NOT NULL,
        reminder_time INTEGER,
        pinned INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        linked_task_id INTEGER,
        visibility TEXT NOT NULL
      )
    ''');
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      orderBy: 'pinned DESC, updated_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
