import 'dart:math';

enum NoteVisibility {
  private,
  public,
  anonymousPublic,
}

class Note {
  final String? id;
  final String title;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool pinned;

  // Reminder
  final bool reminderEnabled;
  final DateTime? reminderTime;

  // Category (future feature)
  final String category;

  final NoteVisibility visibility;

  Note({
    this.id,
    this.title = "",
    this.content = "",
    this.createdAt,
    this.updatedAt,
    this.pinned = false,
    this.reminderEnabled = false,
    this.reminderTime,
    this.category = "General",
    this.visibility = NoteVisibility.private,
  });

  // ---------------------------
  // ID GENERATOR
  // ---------------------------
  static String generateId() {
    final r = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() +
        "_" +
        r.nextInt(999999).toString();
  }

  // ---------------------------
  // COPY
  // ---------------------------
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pinned,
    bool? reminderEnabled,
    DateTime? reminderTime,
    String? category,
    NoteVisibility? visibility,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      category: category ?? this.category,
      visibility: visibility ?? this.visibility,
    );
  }

  // ---------------------------
  // JSON
  // ---------------------------
  factory Note.fromJson(Map<String, dynamic> j) {
    return Note(
      id: j["id"],
      title: j["title"] ?? "",
      content: j["content"] ?? "",
      createdAt: j["createdAt"] != null
          ? DateTime.parse(j["createdAt"])
          : null,
      updatedAt: j["updatedAt"] != null
          ? DateTime.parse(j["updatedAt"])
          : null,
      pinned: j["pinned"] ?? false,
      reminderEnabled: j["reminderEnabled"] ?? false,
      reminderTime: j["reminderTime"] != null
          ? DateTime.parse(j["reminderTime"])
          : null,
      category: j["category"] ?? "General",
      visibility: NoteVisibility.values[j["visibility"] ?? 0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "content": content,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
      "pinned": pinned,
      "reminderEnabled": reminderEnabled,
      "reminderTime": reminderTime?.toIso8601String(),
      "category": category,
      "visibility": visibility.index,
    };
  }
}
