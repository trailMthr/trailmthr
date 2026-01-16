// lib/features/activity/data/activity_repository.dart

import 'package:trailmthr_test2/features/activity/data/activity_db.dart';
import 'package:sqflite/sqflite.dart';

class ActivityRepository {
  final ActivityDb _db = ActivityDb.instance;

  Future<void> createActivity(Map<String, dynamic> activity) async {
    final db = await _db.database;
    await db.insert('activities', activity,
      conflictAlgorithm: ConflictAlgorithm.ignore,
      );
  }
//
  Future<T> transaction<T>(Future<T> Function(dynamic txn) action) async {
    final db = await _db.database;
    return db.transaction((txn) async => action(txn));
  }

  Future<void> updateActivity(String id, Map<String, dynamic> values) async {
    final db = await _db.database;
    await db.update(
      'activities',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getTrackPoints(String activityId) async {
    final db = await _db.database;
    return db.query(
      'activity_points',
      where: 'activity_id = ?',
      whereArgs: [activityId],
      orderBy: 'ts ASC',
    );
  }

  Future<void> insertTrackPoint(Map<String, dynamic> point) async {
    final db = await _db.database;
    await db.insert('activity_points', point);
  }

//
  /// Returns true if an activity exists and has not been finalized (end_time is null).
  Future<bool> hasUnfinishedActivity(String activityId) async {
    final db = await _db.database;
    final rows = await db.query(
      'activities',
      columns: ['id'],
      where: 'id = ? AND end_time IS NULL',
      whereArgs: [activityId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Optional but useful: fetch the activity row (for recovery hydration / debugging).
  Future<Map<String, dynamic>?> getActivityById(String activityId) async {
    final db = await _db.database;
    final rows = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [activityId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Optional integrity gate: detect whether any points exist for the activity.
  Future<bool> hasAnyTrackPoints(String activityId) async {
    final db = await _db.database;
    final rows = await db.query(
      'activity_points',
      columns: ['activity_id'],
      where: 'activity_id = ?',
      whereArgs: [activityId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ------------------------------------------------------------
  // ✅ HISTORY: FETCH ALL ACTIVITIES
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllActivities() async {
    final db = await _db.database;
    return db.query(
      'activities',
      orderBy: 'start_time DESC',
    );
  }
}