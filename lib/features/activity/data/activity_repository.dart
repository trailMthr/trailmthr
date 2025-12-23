// lib/features/activity/data/activity_repository.dart

import 'package:trailmthr_test2/features/activity/data/activity_db.dart';

class ActivityRepository {
  final ActivityDb _db = ActivityDb.instance;

  Future<void> createActivity(Map<String, dynamic> activity) async {
    final db = await _db.database;
    await db.insert('activities', activity);
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