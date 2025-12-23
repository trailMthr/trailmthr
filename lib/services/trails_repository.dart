import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/trail.dart';

class TrailsRepository {
  TrailsRepository._private();
  static final TrailsRepository instance = TrailsRepository._private();

  Database? _db;

  // ------------------------------------------------------------
  // PUBLIC DATABASE GETTER
  // ------------------------------------------------------------
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  // ------------------------------------------------------------
  // INITIALIZE DATABASE
  // ------------------------------------------------------------
  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "trailmthr.db");

    // Open or create DB
    final db = await openDatabase(
      path,
      version: 3, // ← bump when schema changes
      onCreate: (db, _) async {
        await _createTrailsTable(db);
        await _createThinkSpaceTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Legacy upgrade path
        if (oldVersion < 2) {
          await db.execute("DROP TABLE IF EXISTS trails");
          await _createTrailsTable(db);
        }

        // NEW: ThinkSpace integration
        if (oldVersion < 3) {
          await _createThinkSpaceTable(db);
        }
      },
    );

    // ------------------------------------------------------------
    // ENABLE WAL MODE — MASSIVE PERFORMANCE BOOST
    // ------------------------------------------------------------
    await db.rawQuery("PRAGMA journal_mode = WAL;");

    // Optionally increase cache size (improves map + thinkspace speed)
    await db.rawQuery("PRAGMA cache_size = -8000;"); 
    // (negative means KB; so this is ~8MB cache)

    return db;
  }

  // ------------------------------------------------------------
  // TABLE CREATORS
  // ------------------------------------------------------------

  Future<void> _createTrailsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trails (
        id TEXT PRIMARY KEY,
        name TEXT,
        startTime INTEGER,
        endTime INTEGER,
        distance REAL,
        points TEXT
      );
    ''');
  }

  Future<void> _createThinkSpaceTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS think_nodes (
        id TEXT PRIMARY KEY,
        parent_id TEXT,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        created INTEGER NOT NULL,
        updated INTEGER NOT NULL,
        tags TEXT,
        links TEXT,
        importance REAL,
        location_id TEXT,
        activity_id TEXT
      );
    ''');
  }

  // ------------------------------------------------------------
  // TRAIL CRUD OPERATIONS
  // ------------------------------------------------------------
  Future<List<Trail>> getAllTrails() async {
    final db = await database;
    final res = await db.query("trails", orderBy: "startTime DESC");

    return res.map((row) {
      final rawPoints = (row["points"] as String?) ?? "";
      final pts = _decodePointsSafe(rawPoints);
      final rawEnd = (row["endTime"] as int?) ?? 0;

      return Trail(
        id: row["id"] as String,
        name: (row["name"] as String?) ?? "Unnamed",
        startTime:
            DateTime.fromMillisecondsSinceEpoch(row["startTime"] as int),
        endTime: rawEnd > 0
            ? DateTime.fromMillisecondsSinceEpoch(rawEnd)
            : null,
        distanceMeters: (row["distance"] as num?)?.toDouble() ?? 0.0,
        points: pts,
      );
    }).toList();
  }

  Future<void> saveTrail(Trail t) async {
    final db = await database;

    await db.insert(
      "trails",
      {
        "id": t.id,
        "name": t.name,
        "startTime": t.startTime.millisecondsSinceEpoch,
        "endTime": t.endTime?.millisecondsSinceEpoch ?? 0,
        "distance": t.distanceMeters,
        "points": _encodePoints(t.points),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTrail(String id) async {
    final db = await database;
    await db.delete("trails", where: "id = ?", whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete("trails");
  }

  // ------------------------------------------------------------
  // LAT/LNG ENCODE/DECODE HELPERS
  // ------------------------------------------------------------

  String _encodePoints(List<LatLng> pts) {
    if (pts.isEmpty) return "";
    return pts.map((p) => "${p.latitude},${p.longitude}").join(";");
  }

  List<LatLng> _decodePointsSafe(String raw) {
    if (raw.isEmpty) return [];

    final entries = raw.split(";");

    return entries.map((pair) {
      final parts = pair.split(",");
      if (parts.length != 2) return null;

      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat == null || lng == null) return null;

      return LatLng(lat, lng);
    }).whereType<LatLng>().toList();
  }
}
