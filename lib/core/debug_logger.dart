import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

const bool kDebugLoggingEnabled = true;

class DebugLogger {
  static IOSink? _sink;

  static Future<void> start(String activityId) async {
    if (!kDebugLoggingEnabled) return;

    final dir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${dir.path}/debug_logs');

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    final filePath = '${logDir.path}/activity_$activityId.jsonl';

    debugPrint("📁 DEBUG LOG FILE: $filePath");

    _sink = File(filePath).openWrite(mode: FileMode.writeOnlyAppend);

    _sink!.writeln(jsonEncode({
      "ts": DateTime.now().toIso8601String(),
      "event": "logger_started",
      "activity_id": activityId,
    }));
  }

  static void log(Map<String, dynamic> data) {
    if (!kDebugLoggingEnabled) return;
    if (_sink == null) return;

    data["ts"] = DateTime.now().toIso8601String();
    _sink!.writeln(jsonEncode(data));
  }

  static Future<void> close() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}
