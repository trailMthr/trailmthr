import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tm_marker.dart';

class MultiAttributeMarker extends StatelessWidget {
  final TMMarker marker;
  final VoidCallback? onTap;

  const MultiAttributeMarker({
    super.key,
    required this.marker,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final attrs = marker.attributes;
    final maxVisible = 4;

    final visible = attrs.take(maxVisible).toList();
    final extraCount = attrs.length - visible.length;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Mushroom / Flower wooden badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF6B4A2F), 
                    Color(0xFF9B6C3A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.eco, 
                  size: 20,
                  color: Color(0xFFF1E1B0),
                ),
              ),
            ),

            // Petals / spots
            ..._buildAttributeSpots(visible),

            if (extraCount > 0)
              _buildExtraSpot(extraCount),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAttributeSpots(List<MarkerAttribute> attrs) {
    if (attrs.isEmpty) return [];

    final count = attrs.length;
    final radius = 28.0;
    final angleStep = math.pi / (count + 1);
    final startAngle = math.pi + (math.pi - angleStep * (count - 1)) / 2;

    return List.generate(count, (i) {
      final angle = startAngle + angleStep * i;
      final dx = radius * math.cos(angle);
      final dy = radius * math.sin(angle);

      return Positioned(
        left: 26 + dx - 9,
        top: 26 + dy - 9,
        child: _AttributeSpot(type: attrs[i].type),
      );
    });
  }

  Widget _buildExtraSpot(int extraCount) {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Color(0xFF2F4F2F),
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(0xFFF1E1B0),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '+$extraCount',
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFFF1E1B0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttributeSpot extends StatelessWidget {
  final MarkerAttributeType type;

  const _AttributeSpot({required this.type});

  @override
  Widget build(BuildContext context) {
    final (bg, icon) = _colorsAndIconFor(type);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: Color(0xFF1E130A),
          width: 1,
        ),
      ),
      child: Icon(icon, size: 11, color: Color(0xFFFDF7D0)),
    );
  }

  (Color, IconData) _colorsAndIconFor(MarkerAttributeType t) {
    switch (t) {
      case MarkerAttributeType.campsite:
        return (Color(0xFF355E3B), Icons.park);

      case MarkerAttributeType.water:
        return (Color(0xFF2A6F97), Icons.water_drop);

      case MarkerAttributeType.wifi:
        return (Color(0xFF725C3C), Icons.wifi);

      case MarkerAttributeType.bathroom:
        return (Color(0xFF4D6C5B), Icons.wc);

      case MarkerAttributeType.viewpoint:
        return (Color(0xFF7B4F9A), Icons.landscape);

      case MarkerAttributeType.danger:
        return (Color(0xFF8C2B2B), Icons.warning_amber_rounded);

      case MarkerAttributeType.note:
        return (Color(0xFF805A3B), Icons.sticky_note_2);
    }
  }
}
