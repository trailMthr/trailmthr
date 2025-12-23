import 'dart:convert';

class ThinkNode {
  final String id;
  final String? parentId;
  final String type; // idea | concept | thought | brainstorm
  final String content;
  final DateTime created;
  final DateTime updated;
  final List<String> tags;
  final List<String> links;
  final double importance;
  final String? locationId;
  final String? activityId;

  // NEW FIELDS
  final String lifecycleState;   // concept | idea | thought | brainstorm
  final String functionType;     // general | todo | journal | planner | etc

  ThinkNode({
    required this.id,
    required this.type,
    required this.content,
    required this.created,
    required this.updated,
    this.parentId,
    this.tags = const [],
    this.links = const [],
    this.importance = 0.0,
    this.locationId,
    this.activityId,
    this.lifecycleState = "concept",
    this.functionType = "general",
  });

  // ------------------------------------------------------------
  // COPYWITH
  // ------------------------------------------------------------
  ThinkNode copyWith({
    String? id,
    String? parentId,
    String? type,
    String? content,
    DateTime? created,
    DateTime? updated,
    List<String>? tags,
    List<String>? links,
    double? importance,
    String? locationId,
    String? activityId,
    String? lifecycleState,
    String? functionType,
  }) {
    return ThinkNode(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
      content: content ?? this.content,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      tags: tags ?? this.tags,
      links: links ?? this.links,
      importance: importance ?? this.importance,
      locationId: locationId ?? this.locationId,
      activityId: activityId ?? this.activityId,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      functionType: functionType ?? this.functionType,
    );
  }

//
int get childCount => links.length;

  // ------------------------------------------------------------
  // UI Helpers
  // ------------------------------------------------------------
  String get title {
    final lines = content.trim().split('\n');
    if (lines.isEmpty || lines.first.trim().isEmpty) return 'Untitled';
    final t = lines.first.trim();
    return t.length > 80 ? '${t.substring(0, 80)}…' : t;
  }

  String get preview {
    final lines = content.trim().split('\n');
    if (lines.length <= 1) return '';
    final rest = lines.skip(1).join(' ').trim();
    if (rest.isEmpty) return '';
    return rest.length > 100 ? '${rest.substring(0, 100)}…' : rest;
  }

  // ------------------------------------------------------------
  // SERIALIZATION
  // ------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'type': type,
      'content': content,
      'created': created.millisecondsSinceEpoch,
      'updated': updated.millisecondsSinceEpoch,
      'tags': jsonEncode(tags),
      'links': jsonEncode(links),
      'importance': importance,
      'location_id': locationId,
      'activity_id': activityId,
      'lifecycle_state': lifecycleState,
      'function_type': functionType,
    };
  }

  factory ThinkNode.fromMap(Map<String, dynamic> map) {
    List<String> decodeList(dynamic v) {
      if (v == null) return [];
      try {
        final decoded = jsonDecode(v as String);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return [];
    }

    return ThinkNode(
      id: map['id'] as String,
      parentId: map['parent_id'] as String?,
      type: map['type'] as String,
      content: map['content'] as String? ?? '',
      created: DateTime.fromMillisecondsSinceEpoch(map['created'] as int),
      updated: DateTime.fromMillisecondsSinceEpoch(map['updated'] as int),
      tags: decodeList(map['tags']),
      links: decodeList(map['links']),
      importance: (map['importance'] as num?)?.toDouble() ?? 0.0,
      locationId: map['location_id'] as String?,
      activityId: map['activity_id'] as String?,
      lifecycleState: map['lifecycle_state'] as String? ?? "concept",
      functionType: map['function_type'] as String? ?? "general",
    );
  }
}
