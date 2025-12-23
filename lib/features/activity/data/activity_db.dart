// lib/features/activity/data/activity_db.dart

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ActivityDb {
  ActivityDb._private();
  static final ActivityDb instance = ActivityDb._private();

  Database? _database;


  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // ------------------------------------------------------------
  // INITIALIZE DB
  // ------------------------------------------------------------
  Future<Database> _initDb() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = p.join(dir.path, 'trailmthr.db'); // unified DB

    final db = await openDatabase(
      path,
      version: 7, // bump whenever schema changes
      onCreate: (db, _) async {
        await _createActivitiesTable(db);
        await _createActivityPointsTable(db);
        await _createThinkSpaceTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // --- Upgrade to stable unified schema ---

        if (oldVersion < 3) {
          // Completely rebuild broken schemas
          await db.execute('DROP TABLE IF EXISTS activity_points;');
          await db.execute('DROP TABLE IF EXISTS activities;');
        }

        if (oldVersion < 4) {
          // Older versions do not have ThinkSpace
          await db.execute('DROP TABLE IF EXISTS think_nodes;');
        }

if (oldVersion < 4) {
  await db.execute('ALTER TABLE think_nodes ADD COLUMN lifecycle_state TEXT NOT NULL DEFAULT "idea";');
  await db.execute('ALTER TABLE think_nodes ADD COLUMN function_type TEXT NOT NULL DEFAULT "text";');
  await db.execute('ALTER TABLE think_nodes ADD COLUMN archived INTEGER NOT NULL DEFAULT 0;');
  await db.execute('ALTER TABLE think_nodes ADD COLUMN child_count INTEGER NOT NULL DEFAULT 0;');
}

if (oldVersion < 6) {
  await db.execute("ALTER TABLE think_nodes ADD COLUMN is_terminal INTEGER DEFAULT 0;");
}
if (oldVersion < 7) {
  await db.execute(
    "ALTER TABLE think_nodes ADD COLUMN lifecycle_state TEXT NOT NULL DEFAULT 'idea';",
  );
  await db.execute(
    "ALTER TABLE think_nodes ADD COLUMN function_type TEXT NOT NULL DEFAULT 'text';",
  );
  await db.execute(
    "ALTER TABLE think_nodes ADD COLUMN archived INTEGER NOT NULL DEFAULT 0;",
  );
  await db.execute(
    "ALTER TABLE think_nodes ADD COLUMN child_count INTEGER NOT NULL DEFAULT 0;",
  );
}


        // (Re)create correct tables
        await _createActivitiesTable(db);
        await _createActivityPointsTable(db);
        await _createThinkSpaceTable(db);
      },
    );

    // ------------------------------------------------------------
    // SQLITE PERFORMANCE & SAFETY BOOSTS
    // ------------------------------------------------------------
    await db.rawQuery("PRAGMA journal_mode = WAL;");   // safer & faster writes
    await db.rawQuery("PRAGMA synchronous = NORMAL;"); // good balance
    await db.rawQuery("PRAGMA cache_size = -8000;");   // ~8MB page cache

    return db;
  }

  // ------------------------------------------------------------
  // ACTIVITIES TABLE (SUMMARY TABLE)
  // ------------------------------------------------------------
  Future<void> _createActivitiesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        distance_m REAL,
        duration_s REAL,
        avg_pace_min_per_mile REAL,
        notes TEXT
      );
    ''');
  }

  // ------------------------------------------------------------
  // ACTIVITY POINTS TABLE (GPS LOGS)
  // ------------------------------------------------------------
  Future<void> _createActivityPointsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id TEXT NOT NULL,
        ts INTEGER NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        alt REAL,
        accuracy REAL,
        speed REAL,
        vspeed REAL,
        heading REAL,
        movement_state TEXT,
        segment_index INTEGER DEFAULT 0,
        is_gap INTEGER DEFAULT 0,
        FOREIGN KEY(activity_id) REFERENCES activities(id)
      );
    ''');
  }

  // ------------------------------------------------------------
  // THINKSPACE TABLE
  // ------------------------------------------------------------
Future<void> _createThinkSpaceTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS think_nodes (
      id TEXT PRIMARY KEY,
      parent_id TEXT,
      type TEXT NOT NULL,              -- high-level category (idea/journal/etc)
      content TEXT NOT NULL,
      created INTEGER NOT NULL,
      updated INTEGER NOT NULL,
      tags TEXT,
      links TEXT,
      importance REAL,
      location_id TEXT,
      activity_id TEXT,
      is_terminal INTEGER DEFAULT 0,

      -- NEW: lifecycle state & functional type
      lifecycle_state TEXT NOT NULL DEFAULT 'idea',
      function_type TEXT NOT NULL DEFAULT 'text',

      -- NEW: housekeeping
      archived INTEGER NOT NULL DEFAULT 0,
      child_count INTEGER NOT NULL DEFAULT 0
    );
  ''');
}


  // ------------------------------------------------------------
  // ACTIVITY CRUD
  // ------------------------------------------------------------
  Future<void> createActivity(Map<String, dynamic> activity) async {
    final db = await database;
    await db.insert(
      'activities',
      activity,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateActivity(String id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update(
      'activities',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllActivities() async {
    final db = await database;
    return db.query(
      'activities',
      orderBy: 'start_time DESC',
    );
  }

  Future<Map<String, dynamic>?> getActivityById(String id) async {
    final db = await database;
    final rows = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> deleteActivity(String id) async {
    final db = await database;

    await db.delete(
      'activity_points',
      where: 'activity_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------
  // TRACKPOINT LOGGING
  // ------------------------------------------------------------
  Future<void> insertTrackPoint(Map<String, dynamic> point) async {
    final db = await database;
    await db.insert(
      'activity_points',
      point,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Map<String, dynamic>>> getTrackPoints(String activityId) async {
    final db = await database;
    return db.query(
      'activity_points',
      where: 'activity_id = ?',
      whereArgs: [activityId],
      orderBy: 'ts ASC',
    );
  }
}
