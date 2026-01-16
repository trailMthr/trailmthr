import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DebugExport {
  static Future<String?> exportLogs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/debug_logs');

      if (!await logDir.exists()) return null;

      final downloads = Directory('/storage/emulated/0/Download/trailmthr_logs');

      if (!await downloads.exists()) {
        await downloads.create(recursive: true);
      }

      await for (final file in logDir.list()) {
        if (file is File) {
          final name = file.uri.pathSegments.last;
          await file.copy('${downloads.path}/$name');
        }
      }

      return downloads.path;
    } catch (e) {
      return null;
    }
  }
}
