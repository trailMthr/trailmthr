# Recovery & Resume Protocol (v0.1)

## Preconditions
- Ensure GPS permission granted.
- Ensure notifications permission granted (Android 13+).
- Start from MapScreen with LiveStatsPanel visible.

## Test Cases

### T1 — Force-close while recording
1. Start activity (walk).
2. Walk 10–30 seconds.
3. Force-close app.
4. Reopen app → MapScreen.
Expected:
- Exactly one resume prompt.
- No silent recording before user action.
- Resuming continues same activityId and polyline.

### T2 — Force-close while paused
1. Start activity.
2. Pause.
3. Force-close.
4. Reopen → MapScreen.
Expected:
- Resume prompt shown.
- Session remains paused until Resume.
- Elapsed remains stable (pause-safe).

### T3 — Resume stability
1. From T1/T2, tap Resume once.
Expected:
- No multiple prompts.
- Timer repaints continuously.
- Recorder stream reattaches and GPS fixes resume.

### T4 — Discard
1. From prompt, choose Discard.
Expected:
- No further prompt on next launch.
- Session cleared (controller + recorder).
