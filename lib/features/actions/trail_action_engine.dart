// lib/features/actions/trail_action_engine.dart

import 'package:flutter/material.dart';

typedef AsyncActionCallback = Future<void> Function();

class TrailQuickAction {
  final IconData icon;
  final String label;
  final AsyncActionCallback onTap;

  TrailQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class TrailAdvancedItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final void Function(BuildContext context) onTap;

  TrailAdvancedItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

class TrailAdvancedSection {
  final IconData icon;
  final String title;
  final List<TrailAdvancedItem> items;

  TrailAdvancedSection({
    required this.icon,
    required this.title,
    required this.items,
  });
}

class TrailActionEngine {
  TrailActionEngine._internal();
  static final TrailActionEngine instance = TrailActionEngine._internal();

  // Callbacks that MapScreen (or others) register:
  AsyncActionCallback? startStopRecording;
  AsyncActionCallback? centerGps;
  AsyncActionCallback? addMarkerHere;
  AsyncActionCallback? showSavedPlaces;

  // To let the engine know if we're currently recording
  bool Function()? isRecording;

  // To allow the map to tell the shell "user tapped/moved the map"
  VoidCallback? onMapInteraction;

  /// Quick actions that the FAB row shows.
  List<TrailQuickAction> get quickActions {
    final actions = <TrailQuickAction>[];

    if (startStopRecording != null) {
      final recording = isRecording?.call() ?? false;
      actions.add(
        TrailQuickAction(
          icon: recording ? Icons.stop : Icons.play_arrow,
          label: recording ? 'Stop' : 'Start',
          onTap: startStopRecording!,
        ),
      );
    }

    if (centerGps != null) {
      actions.add(
        TrailQuickAction(
          icon: Icons.my_location,
          label: 'GPS',
          onTap: centerGps!,
        ),
      );
    }

    if (showSavedPlaces != null) {
      actions.add(
        TrailQuickAction(
          icon: Icons.bookmark,
          label: 'Saved',
          onTap: showSavedPlaces!,
        ),
      );
    }

    if (addMarkerHere != null) {
      actions.add(
        TrailQuickAction(
          icon: Icons.add_location_alt,
          label: 'Mark',
          onTap: addMarkerHere!,
        ),
      );
    }

    return actions;
  }

  /// Sections for the long-press advanced menu.
  List<TrailAdvancedSection> buildAdvancedSections() {
    return [
      TrailAdvancedSection(
        icon: Icons.navigation,
        title: 'Navigation',
        items: [
          TrailAdvancedItem(
            icon: Icons.layers,
            title: 'Map layers',
            subtitle: 'Switch OSM / satellite / topo (coming soon)',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.straighten,
            title: 'Measure distance',
            subtitle: 'Tap along a path to measure (coming soon)',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.assistant_navigation,
            title: 'Bearing to waypoint',
            subtitle: 'Point toward selected waypoint (coming soon)',
            onTap: _comingSoon,
          ),
        ],
      ),
      TrailAdvancedSection(
        icon: Icons.place,
        title: 'Markers',
        items: [
          TrailAdvancedItem(
            icon: Icons.water_drop,
            title: 'Add water source',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.cabin,
            title: 'Add campsite',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.wc,
            title: 'Add restroom',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.store,
            title: 'Add resupply point',
            onTap: _comingSoon,
          ),
        ],
      ),
      TrailAdvancedSection(
        icon: Icons.construction,
        title: 'Trail tools',
        items: [
          TrailAdvancedItem(
            icon: Icons.note_alt,
            title: 'Trail diary entry',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.flag,
            title: 'Drop geocache',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.mic,
            title: 'Voice note',
            onTap: _comingSoon,
          ),
        ],
      ),
      TrailAdvancedSection(
        icon: Icons.settings,
        title: 'System & environment',
        items: [
          TrailAdvancedItem(
            icon: Icons.cloud,
            title: 'Weather bar',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.wb_sunny,
            title: 'Sunset countdown',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.offline_bolt,
            title: 'Offline mode',
            onTap: _comingSoon,
          ),
          TrailAdvancedItem(
            icon: Icons.bug_report,
            title: 'Developer panel',
            onTap: _comingSoon,
          ),
        ],
      ),
    ];
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon to TrailMthr ✨'),
      ),
    );
  }
}
