import 'package:latlong2/latlong.dart';

enum MarkerAttributeType {
  campsite,
  water,
  wifi,
  bathroom,
  viewpoint,
  danger,
  note,
}

class MarkerAttribute {
  final MarkerAttributeType type;
  final String? label; 
  final Map<String, dynamic>? extra; 

  MarkerAttribute({
    required this.type,
    this.label,
    this.extra,
  });
}

class TMMarker {
  final String id;
  final LatLng coords;
  final List<MarkerAttribute> attributes;

  TMMarker({
    required this.id,
    required this.coords,
    required this.attributes,
  });
}
