// lib/features/map/data/saved_place_db.dart

import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SavedPlaceDb {
  SavedPlaceDb._private();
  static final SavedPlaceDb instance = SavedPlaceDb._private();

  static Database? _database;

  // ------------------------------------------------------------
  // PUBLIC DATABASE GETTER
  // ------------------------------------------------------------
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // ------------------------------------------------------------
  // DATABASE INITIALIZATION + MIGRATION
  // ------------------------------------------------------------
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'trailmthr_places.db');

    return await openDatabase(
      path,
      version: 5, // ✅ bumped for owner_id / visibility / locked

      // ✅ Fresh install
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE places (
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT,
            lat REAL,
            lng REAL,
            created_at INTEGER,
            notes TEXT,
            tags TEXT,
rating_avg REAL,
reviews_json TEXT,



            owner_id TEXT,
            visibility TEXT,
            locked INTEGER
          )
        ''');
        await db.execute('''
  CREATE TABLE notes (
    id TEXT PRIMARY KEY,
    text TEXT,
    lat REAL,
    lng REAL,
    created_at INTEGER,
    source TEXT,        -- idea, whisper, trekmaster, message, etc
    visibility TEXT     -- private, public
  )
''');

        await db.execute('''
  CREATE TABLE notes (
    id TEXT PRIMARY KEY,
    text TEXT,
    lat REAL,
    lng REAL,
    created_at INTEGER
  )
''');

      },

      // ✅ Migration for existing users
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE places ADD COLUMN owner_id TEXT',
          );
          await db.execute(
            'ALTER TABLE places ADD COLUMN visibility TEXT',
          );
          await db.execute(
            'ALTER TABLE places ADD COLUMN locked INTEGER DEFAULT 0',
          );
        }
if (oldVersion < 5) {
  await db.execute('ALTER TABLE notes ADD COLUMN source TEXT');
  await db.execute('ALTER TABLE notes ADD COLUMN visibility TEXT');
}

if (oldVersion < 4) {
  await db.execute('''
    CREATE TABLE notes (
      id TEXT PRIMARY KEY,
      text TEXT,
      lat REAL,
      lng REAL,
      created_at INTEGER
    )
  ''');
}

if (oldVersion < 3) {
  await db.execute(
    'ALTER TABLE places ADD COLUMN rating_avg REAL',
  );
  await db.execute(
    'ALTER TABLE places ADD COLUMN reviews_json TEXT',
  );
}

      },
    );
  }

  // ------------------------------------------------------------
  // CRUD OPERATIONS
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllPlaces() async {
    final db = await database;
    return await db.query(
      'places',
      orderBy: 'created_at DESC',
    );
  }

Future<void> insertNote(Map<String, dynamic> note) async {
  final db = await database;
  await db.insert('notes', note);
}

Future<List<Map<String, dynamic>>> getAllNotes() async {
  final db = await database;
  return await db.query('notes', orderBy: 'created_at DESC');
}

  Future<void> upsertPlace(Map<String, dynamic> place) async {
    final db = await database;
    await db.insert(
      'places',
      place,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePlaceById(String id) async {
    final db = await database;
    await db.delete(
      'places',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
