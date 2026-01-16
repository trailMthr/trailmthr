# TrailMthr System Inventory (living document)

Last updated: 2026-01-12

## Principles
- One truth source per domain (avoid duplicate “spines”)
- UI renders state; controllers decide; repos persist
- Deprecated files must be quarantined or deleted

---

## Activity System (Live Recording)
### Entry points
- Map screen: lib/features/map/screens/map_screen.dart
- Live stats panel: lib/features/activity/widgets/live_stats_panel.dart

### Core components
- Live controller (time + snapshot): lib/features/activity/controllers/live_activity_controller.dart
- Recorder (GPS + DB writes): lib/features/activity/controllers/activity_recorder.dart
- Repository (DB): lib/features/activity/data/activity_repository.dart
- DB: lib/features/activity/data/activity_db.dart

### Key flows
- Start: UI -> Recorder.start -> Repo.createActivity -> Controller.start (or recorder orchestrates)
- Pause/Resume: UI -> Recorder.pause/unpause -> Controller.pause/resume
- Stop: UI -> Recorder.finishAndSave -> Repo.updateActivity + points + ThinkSpace hook
- Recovery: Controller snapshot -> UI prompt -> Recorder attaches to existing activityId

### Known issues / tests
- [ ] Pause must freeze both time + distance
- [ ] Kill/restart should show resume prompt if unfinished activity exists
- [ ] Blue dot should follow latest GPS

---

## Map System
### Core files
- Map screen: lib/features/map/screens/map_screen.dart
- Map controller usage: (note here)

### Known issues
- Blue dot not following polyline (separate position state)

---

## ThinkSpace System
### Core files
- ThinkSpace repository: (path)
- Inserts on activity end: activity_recorder.dart -> thinkRepo.insertTrailObject

---

## Suspected deprecated/unused files (quarantine candidates)
- (list as discovered)

## TODO: Quarantine process
- Move deprecated files to /lib/_graveyard/ with README explaining why
- Remove imports/refs, confirm build, then delete permanently

## movement ledger (planned, consent required)
