import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DataExportService {
  /// Dump all non-internal tables to a single JSON file.
  ///
  /// Returns the File that was written.
  static Future<File> exportFullDatabase(Database db) async {
    // Get all user tables
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type='table' AND name NOT LIKE 'sqlite_%' "
      "ORDER BY name",
    );

    final Map<String, dynamic> dump = {
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{},
    };

    final Map<String, dynamic> tableData = {};

    for (final row in tables) {
      final tableName = row['name'] as String;
      final rows = await db.query(tableName);
      tableData[tableName] = rows;
    }

    dump['tables'] = tableData;

    // Decide where to write it
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll('-', '');
    final fileName = 'trailmthr_export_$timestamp.json';
    final file = File('${dir.path}/$fileName');

    final jsonStr = const JsonEncoder.withIndent('  ').convert(dump);
    await file.writeAsString(jsonStr);

    return file;
  }
}
