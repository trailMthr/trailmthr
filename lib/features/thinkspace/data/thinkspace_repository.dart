// lib/features/thinkspace/data/thinkspace_repository.dart
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/think_node.dart';

import 'package:trailmthr_test2/core/trail_objects/trail_object.dart';
import 'dart:convert';

class ThinkSpaceRepository {
  final Future<Database> Function() _getDb;
  static const _table = 'think_nodes';
  static const _uuid = Uuid();

  ThinkSpaceRepository(this._getDb);

  // Ensure table exists (safe to call at startup)
  Future<void> ensureTable() async {
    final db = await _getDb();
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
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
        activity_id TEXT,

        lifecycle_state TEXT NOT NULL DEFAULT 'idea',
        function_type TEXT NOT NULL DEFAULT 'text',
        archived INTEGER NOT NULL DEFAULT 0,
        child_count INTEGER NOT NULL DEFAULT 0
      );
CREATE TABLE IF NOT EXISTS trail_objects (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  lat REAL,
  lng REAL,
  payload TEXT NOT NULL,
  source TEXT NOT NULL
);

    ''');
  }

  // ------------------------------------------------------------
  // CREATE
  // ------------------------------------------------------------

  Future<ThinkNode> createNode({
    String? id,
    String? parentId,
    required String type,
    required String content,
    List<String> tags = const [],
    List<String> links = const [],
    double importance = 0.0,
    String? locationId,
    String? activityId,

    // NEW OPTIONAL FIELDS
    String lifecycleState = 'idea',
    String functionType = 'text',
    bool archived = false,
  }) async {
    final db = await _getDb();
    final now = DateTime.now();

    final node = ThinkNode(
      id: id ?? _uuid.v4(),
      parentId: parentId,
      type: type,
      content: content,
      created: now,
      updated: now,
      tags: tags,
      links: links,
      importance: importance,
      locationId: locationId,
      activityId: activityId,
      lifecycleState: lifecycleState,
      functionType: functionType,

    );

    await db.insert(
      _table,
      node.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return node;
  }

//
Future<void> insertTrailObject(TrailObject obj) async {
  final db = await _getDb();

  // ✅ Ensure table exists before insert
  await db.execute('''
    CREATE TABLE IF NOT EXISTS trail_objects (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      lat REAL,
      lng REAL,
      payload TEXT NOT NULL,
      source TEXT NOT NULL
    );
  ''');

  await db.insert(
    'trail_objects',
    {
      'id': obj.id,
      'type': obj.type,
      'timestamp': obj.timestamp.toIso8601String(),
      'lat': obj.lat,
      'lng': obj.lng,
      'payload': jsonEncode(obj.payload),
      'source': obj.source,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}


  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------

  Future<void> updateNode(ThinkNode node) async {
    final db = await _getDb();
    final updated = node.copyWith(updated: DateTime.now());
    await db.update(
      _table,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [node.id],
    );
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<void> deleteNode(String id) async {
    final db = await _getDb();
    await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------
  // GET SINGLE NODE
  // ------------------------------------------------------------

  Future<ThinkNode?> getNode(String id) async {
    final db = await _getDb();
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ThinkNode.fromMap(rows.first);
  }

  // ------------------------------------------------------------
  // GET CHILDREN
  // ------------------------------------------------------------

  Future<List<ThinkNode>> getChildren(String parentId) async {
    final db = await _getDb();
    final rows = await db.query(
      _table,
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'created ASC',
    );
    return rows.map((m) => ThinkNode.fromMap(m)).toList();
  }

  // ------------------------------------------------------------
  // ROOT NODES (no parent)
  // ------------------------------------------------------------
  Future<List<ThinkNode>> getRootNodes({bool includeArchived = false}) async {
    final db = await _getDb();

    final where = includeArchived ? 'parent_id IS NULL' : 'parent_id IS NULL AND archived = 0';

    final rows = await db.query(
      _table,
      where: where,
      orderBy: 'updated DESC',
    );

    return rows.map((m) => ThinkNode.fromMap(m)).toList();
  }

  // -----------------------------
  // RELATIONSHIP HELPERS
  // -----------------------------

  Future<ThinkNode?> getParentOf(ThinkNode node) async {
    if (node.parentId == null) return null;
    return getNode(node.parentId!);
  }

  Future<List<ThinkNode>> getChildrenOf(ThinkNode node) async {
    return getChildren(node.id);
  }

  Future<List<ThinkNode>> getSiblingsOf(ThinkNode node) async {
    if (node.parentId == null) return [];
    final db = await _getDb();

    final rows = await db.query(
      _table,
      where: 'parent_id = ? AND id != ?',
      whereArgs: [node.parentId, node.id],
      orderBy: 'created ASC',
    );

    return rows.map((m) => ThinkNode.fromMap(m)).toList();
  }

  Future<List<ThinkNode>> getLinkedNodes(ThinkNode node) async {
    if (node.links.isEmpty) return [];
    final db = await _getDb();

    final qMarks = List.filled(node.links.length, '?').join(',');
    final rows = await db.query(
      _table,
      where: 'id IN ($qMarks)',
      whereArgs: node.links,
    );

    return rows.map((m) => ThinkNode.fromMap(m)).toList();
  }

  // ------------------------------------------------------------
  // SEARCH / FILTER
  // ------------------------------------------------------------

  Future<List<ThinkNode>> searchNodes({
    String? query,
    String? typeFilter,
    List<String>? tagFilter,
    int limit = 200,
  }) async {
    final db = await _getDb();
    final where = <String>[];
    final args = <Object?>[];

    if (query != null && query.trim().isNotEmpty) {
      where.add('content LIKE ?');
      args.add('%${query.trim()}%');
    }

    if (typeFilter != null && typeFilter.isNotEmpty) {
      where.add('type = ?');
      args.add(typeFilter);
    }

    if (tagFilter != null && tagFilter.isNotEmpty) {
      for (final tag in tagFilter) {
        where.add('tags LIKE ?');
        args.add('%"$tag"%');
      }
    }

    final whereClause = where.isEmpty ? null : where.join(' AND ');

    final rows = await db.query(
      _table,
      where: whereClause,
      whereArgs: args,
      orderBy: 'updated DESC',
      limit: limit,
    );

    return rows.map((m) => ThinkNode.fromMap(m)).toList();
  }

  // ------------------------------------------------------------
  // CONVENIENCE FILTERS
  // ------------------------------------------------------------

  Future<List<ThinkNode>> getAllQuickNotes({int limit = 100}) {
    return searchNodes(typeFilter: 'quicknote', limit: limit);
  }

  Future<List<ThinkNode>> getInbox({int limit = 200}) async {
    return searchNodes(limit: limit);
  }

  // ------------------------------------------------------------
  // LIFECYCLE COUNTS (for Structure section)
  // ------------------------------------------------------------

  Future<Map<String, int>> getLifecycleCounts() async {
    final db = await _getDb();

    final rows = await db.rawQuery('''
      SELECT lifecycle_state, archived, COUNT(*) AS cnt
      FROM $_table
      GROUP BY lifecycle_state, archived;
    ''');

    int perspectives = 0;
    int brainstorms = 0;
    int thoughts = 0;
    int concepts = 0;
    int ideas = 0;
    int quicknotes = 0;
    int archive = 0;

    for (final row in rows) {
      final state = (row['lifecycle_state'] as String?) ?? 'idea';
      final archivedFlag = (row['archived'] as int?) ?? 0;
      final count = (row['cnt'] as int?) ?? 0;

      if (archivedFlag == 1) {
        archive += count;
        continue;
      }

      switch (state) {
        case 'perspective':
          perspectives += count;
          break;
        case 'brainstorm':
          brainstorms += count;
          break;
        case 'thought':
          thoughts += count;
          break;
        case 'concept':
          concepts += count;
          break;
        case 'quicknote':
          quicknotes += count;
          break;
        case 'idea':
        default:
          ideas += count;
          break;
      }
    }

    return {
      'perspectives': perspectives,
      'brainstorms': brainstorms,
      'thoughts': thoughts,
      'concepts': concepts,
      'ideas': ideas,
      'quicknotes': quicknotes,
      'archive': archive,
    };
  }
}
