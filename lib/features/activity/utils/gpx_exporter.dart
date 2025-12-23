import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import '../models/activity_models.dart';

class GpxExporter {
  /// Creates a GPX file from a session + raw track points.
  /// Returns the file path.
  static Future<String> exportSessionToGpx(
    ActivitySession session,
    List<LatLng> trackPoints,
  ) async {
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('gpx', nest: () {
      builder.attribute('version', '1.1');
      builder.attribute('creator', 'TrailMthr');

      builder.element('trk', nest: () {
        builder.element('name', nest: session.type.label);
        builder.element('desc', nest: session.notes);

        builder.element('trkseg', nest: () {
          for (final pnt in trackPoints) {
            builder.element('trkpt', nest: () {
              builder.attribute('lat', pnt.latitude.toStringAsFixed(6));
              builder.attribute('lon', pnt.longitude.toStringAsFixed(6));
              // Optional elevation; we don't track real elevation per point yet:
              builder.element('ele', nest: '0');
              builder.element('time', nest: session.startTime.toUtc().toIso8601String());
            });
          }
        });
      });
    });

    final doc = builder.buildDocument();

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        "tm_${session.startTime.toIso8601String().replaceAll(":", "-")}.gpx";
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(doc.toXmlString(pretty: true));

    return file.path;
  }
}
