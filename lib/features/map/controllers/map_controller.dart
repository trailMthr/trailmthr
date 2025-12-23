// lib/features/map/controllers/map_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/trail_point.dart';

/// Controller that owns mapController, list of points, selection state,
/// and helper navigation methods. Keeps UI logic out of widgets.
class TrailMapController extends ChangeNotifier {
  final MapController mapController = MapController();

  /// Replace these with real data / loading from JSON or API later.
  final List<TrailPoint> _points = [
    TrailPoint(
      id: 'sf',
      title: 'San Francisco',
      location: LatLng(37.7749, -122.4194),
      description: 'San Francisco, CA',
      type: 'city',
    ),
    TrailPoint(
      id: 'la',
      title: 'Los Angeles',
      location: LatLng(34.0522, -118.2437),
      description: 'Los Angeles, CA',
      type: 'city',
    ),
    TrailPoint(
      id: 'lv',
      title: 'Las Vegas',
      location: LatLng(36.1699, -115.1398),
      description: 'Las Vegas, NV',
      type: 'city',
    ),
  ];

  TrailPoint? _selectedPoint;

  List<TrailPoint> get points => List.unmodifiable(_points);

  TrailPoint? get selectedPoint => _selectedPoint;

  /// Choose sensible initial center
  LatLng get initialCenter => _points.first.location;

  /// Select a point (e.g., on marker tap)
  void selectPoint(TrailPoint point) {
    _selectedPoint = point;
    notifyListeners();
  }

  /// Deselect current point
  void clearSelection() {
    _selectedPoint = null;
    notifyListeners();
  }

  /// Move camera to a point with animation (if map controller is attached)
  void moveToPoint(TrailPoint point, {double zoom = 12.0}) {
    try {
      mapController.move(point.location, zoom);
    } catch (e) {
      // mapController may not be ready; swallow for now
      if (kDebugMode) {
        print('moveToPoint failed: $e');
      }
    }
  }

  /// Go to initial point (used by FAB)
  void goToInitialPoint() {
    moveToPoint(_points.first, zoom: 7.0);
  }

  /// Build polyline points (straight connect in index order)
  List<LatLng> get polylinePoints =>
      _points.map((p) => p.location).toList(growable: false);
}
