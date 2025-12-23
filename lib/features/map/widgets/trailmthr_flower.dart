// lib/features/map/widgets/trailmthr_flower.dart

import 'package:flutter/material.dart';

class TrailMthrFlower extends StatefulWidget {
  final VoidCallback onStartActivity;
  final VoidCallback onOpenMarkers;
  final VoidCallback onOpenIdeas;
  final VoidCallback onOpenTrekMaster;
final VoidCallback? onOpenActivityHistory;

  /// If true, main bud glows to indicate recording
  final bool isRecording;

  const TrailMthrFlower({
    super.key,
    required this.onStartActivity,
    required this.onOpenMarkers,
    required this.onOpenIdeas,
    required this.onOpenTrekMaster,
    this.isRecording = false,
    this.onOpenActivityHistory,
  });

  @override
  State<TrailMthrFlower> createState() => _TrailMthrFlowerState();
}

class _TrailMthrFlowerState extends State<TrailMthrFlower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;
  late final Animation<double> _menuAnim;

  bool _menuOpen = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _menuAnim = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInQuad,
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _menuOpen = !_menuOpen;
    });
    if (_menuOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  void _handlePetalTap(VoidCallback cb, String label) {
    debugPrint("✅ PETAL TAP: $label");
    _toggleMenu();
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ---------------- PETALS ----------------
              _buildPetal(
                alignment: const Alignment(-0.8, -0.1),
                label: 'Markers',
                icon: Icons.place_rounded,
                onTap: () => _handlePetalTap(
                  widget.onOpenMarkers,
                  'Markers',
                ),
              ),
              _buildPetal(
                alignment: const Alignment(0.0, -0.9),
                label: 'Start',
                icon: Icons.play_arrow_rounded,
                onTap: () => _handlePetalTap(
                  widget.onStartActivity,
                  'Start Activity',
                ),
                onLongPress: widget.onOpenActivityHistory,
              ),
              _buildPetal(
                alignment: const Alignment(0.8, -0.1),
                label: 'Ideas',
                icon: Icons.lightbulb_rounded,
                onTap: () => _handlePetalTap(
                  widget.onOpenIdeas,
                  'Ideas',
                ),
              ),
              _buildPetal(
                alignment: const Alignment(0.0, -1.4),
                label: 'TrekMaster',
                icon: Icons.auto_awesome_rounded,
                onTap: () => _handlePetalTap(
                  widget.onOpenTrekMaster,
                  'TrekMaster',
                ),
              ),

              // ---------------- CORE tM BUTTON ----------------
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildCoreButton(colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoreButton(ColorScheme colorScheme) {
    final baseColor = colorScheme.primary;
    final surface = colorScheme.surface;

    return AnimatedBuilder(
      animation: Listenable.merge([_menuAnim]),
      builder: (context, child) {
        final menuBoost = 1.0 + (_menuAnim.value * 0.03);
        final pressScale = _pressed ? 0.94 : 1.0;
        final totalScale = pressScale * menuBoost;

        final glowIntensity = widget.isRecording ? 1.0 : _menuAnim.value;
        final shadowBlur = 12.0 + 10.0 * glowIntensity;

        return Transform.scale(
          scale: totalScale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surface,
              boxShadow: [
                BoxShadow(
                  color: widget.isRecording
                      ? baseColor.withOpacity(0.55)
                      : baseColor.withOpacity(0.25 + 0.25 * glowIntensity),
                  blurRadius: shadowBlur,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: _toggleMenu,
              child: SizedBox(
                width: 80,
                height: 80,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.forest_rounded,
                        size: 32,
                        color: baseColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'tM',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.8,
                          color: baseColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPetal({
    required Alignment alignment,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return AnimatedBuilder(
      animation: _menuAnim,
      builder: (context, child) {
        final t = _menuAnim.value.clamp(0.0, 1.0);
        if (t == 0.0) return const SizedBox.shrink();

        return Align(
          alignment: alignment,
          child: Opacity(
            opacity: t,
            child: Transform.scale(
              scale: t,
              child: child,
            ),
          ),
        );
      },
      child: _PetalButton(
        label: label,
        icon: icon,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class _PetalButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // ✅ ADD

  const _PetalButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.onLongPress, // ✅ ADD
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // ✅ grabs taps reliably
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: colorScheme.surface.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
