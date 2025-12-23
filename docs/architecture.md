# TrailMthr – Architecture Snapshot

## App Shell
- MainAppShell manages tab navigation
- Map is default entry point
- Activity and ThinkSpace are first-class systems

## Map System
- Flutter Map
- Offline tile support (in progress)
- Marker layers (camps, water, hazards, etc.)
- GPS location tracking

## Activity System
- LiveActivityController governs lifecycle
- ActivityRecorder handles data capture
- SQLite persistence
- Recovery on app restart (partial)

## ThinkSpace
- Structured notes / ideas / logs
- Can attach to activities
- Optional system (no hard dependency)

## Data Flow (High Level)
- GPS → ActivityRecorder → SQLite
- Activity summary → ThinkSpace (manual)
- Map reads markers + activity overlays

## Explicit Non-Connections
- ThinkSpace does not control Activity lifecycle
- Map does not write directly to ThinkSpace
- UI reflects state but does not own it
