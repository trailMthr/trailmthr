# TrailMthr – Architecture Snapshot

## App Shell
- MainAppShell manages top-level navigation and lifecycle
- Map is the default entry point on launch
- Activity and ThinkSpace are first-class systems, not subordinate features

## Map System
- Built on Flutter Map
- Supports offline tile caching (work in progress)
- Marker layers (camps, water, hazards, etc.)
- GPS-based user location tracking
- Reads persisted activity overlays and markers

## Activity System
- LiveActivityController governs activity lifecycle state
- ActivityRecorder handles GPS sampling and metric capture
- SQLite persistence for all recorded activities
- Recovery on app restart is supported but not yet exhaustive

## ThinkSpace
- Structured notes, ideas, and logs
- Can be linked to activities but does not depend on them
- Optional system that must not block core app functionality

## Data Flow (High Level)
- GPS → ActivityRecorder → SQLite
- Activity summaries → ThinkSpace (manual user action)
- Map renders markers and activity overlays from persisted data

## Explicit Non-Connections
- ThinkSpace does not control or mutate Activity lifecycle
- Map does not write directly to ThinkSpace
- UI reflects system state but does not own or derive truth
