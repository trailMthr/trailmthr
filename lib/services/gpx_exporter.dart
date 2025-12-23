import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/trail_record.dart';

class GpxExporter {
  static Future<File> exportTrail(TrailRecord trail) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = trail.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final file =
        File("${dir.path}/${safeName.isEmpty ? "trail" : safeName}_${trail.id}.gpx");

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<gpx version="1.1" creator="TrailMthr" xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('<trk>');
    buffer.writeln('<name>${trail.name}</name>');
    buffer.writeln('<trkseg>');

    for (final p in trail.points) {
      buffer.writeln(
          '<trkpt lat="${p.latitude}" lon="${p.longitude}"></trkpt>');
    }

    buffer.writeln('</trkseg>');
    buffer.writeln('</trk>');
    buffer.writeln('</gpx>');

    await file.writeAsString(buffer.toString());
    return file;
  }
}
