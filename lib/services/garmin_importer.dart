import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';
import '../models/trail_record.dart';
import 'trail_database.dart';

class GarminImporter {
  static Future<TrailRecord?> importGpxFile(File file) async {
    final xmlStr = await file.readAsString();
    final doc = XmlDocument.parse(xmlStr);

    // GPX uses namespaces sometimes. We'll ignore prefix by matching localName.
    final trkpts = doc
        .findAllElements('trkpt')
        .toList();

    if (trkpts.length < 2) return null;

    final points = <LatLng>[];
    DateTime? start;
    DateTime? end;

    for (final p in trkpts) {
      final lat = double.parse(p.getAttribute('lat')!);
      final lon = double.parse(p.getAttribute('lon')!);
      points.add(LatLng(lat, lon));

      final timeEl = p.findElements('time').isNotEmpty
          ? p.findElements('time').first
          : null;
      if (timeEl != null) {
        final t = DateTime.tryParse(timeEl.text.trim());
        if (t != null) {
          start ??= t;
          end = t;
        }
      }
    }

    // Fallback times if GPX missing time tags
    start ??= DateTime.now();
    end ??= start;

    // crude distance calc
    const dist = Distance();
    double meters = 0;
    for (int i = 1; i < points.length; i++) {
      meters += dist(points[i - 1], points[i]);
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final name = file.uri.pathSegments.last.replaceAll('.gpx', '');

    final trail = TrailRecord(
      id: id,
      name: name,
      startTime: start,
      endTime: end,
      points: points,
      distanceMeters: meters,
      importedFromGarmin: true,
    );

    await TrailDatabase.instance.insertTrail(trail);
    return trail;
  }
}
