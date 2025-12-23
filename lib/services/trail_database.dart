import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/trail_record.dart';

class TrailDatabase {
  static final TrailDatabase instance = TrailDatabase._();
  TrailDatabase._();

  static const _dbName = "trailmthr.db";
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trails (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            startTime TEXT NOT NULL,
            endTime TEXT NOT NULL,
            distanceMeters REAL NOT NULL,
            importedFromGarmin INTEGER NOT NULL,
            pointsJson TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---------- CRUD ----------

  Future<void> insertTrail(TrailRecord t) async {
    final db = await database;
    await db.insert(
      "trails",
      {
        "id": t.id,
        "name": t.name,
        "startTime": t.startTime.toIso8601String(),
        "endTime": t.endTime.toIso8601String(),
        "distanceMeters": t.distanceMeters,
        "importedFromGarmin": t.importedFromGarmin ? 1 : 0,
        "pointsJson": jsonEncode(
          t.points.map((p) => {"lat": p.latitude, "lng": p.longitude}).toList(),
        ),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TrailRecord>> getAllTrails() async {
    final db = await database;
    final rows = await db.query("trails", orderBy: "startTime DESC");

    return rows.map((r) {
      final pts = (jsonDecode(r["pointsJson"] as String) as List)
          .map((e) => LatLng(
                (e["lat"] as num).toDouble(),
                (e["lng"] as num).toDouble(),
              ))
          .toList();

      return TrailRecord(
        id: r["id"] as String,
        name: r["name"] as String,
        startTime: DateTime.parse(r["startTime"] as String),
        endTime: DateTime.parse(r["endTime"] as String),
        distanceMeters: (r["distanceMeters"] as num).toDouble(),
        importedFromGarmin: (r["importedFromGarmin"] as int) == 1,
        points: pts,
      );
    }).toList();
  }

  Future<void> deleteTrail(String id) async {
    final db = await database;
    await db.delete("trails", where: "id = ?", whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete("trails");
  }
}
