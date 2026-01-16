---
title: TrailMthr Activity Core Loop Contract
version: v0.1
status: Intent-Frozen
date: 2026-01-15
scope: Activity recording + recovery + UI truth
---

## Principles

### Single Source of Truth
- **LiveActivityController owns time truth** (elapsed = raw - pausedTotal).
- **ActivityRecorder owns path truth** (track points + polyline + DB writes).
- UI must never invent values; it renders controller/recorder truth only.

### Identity
- A live session has exactly one `activityId`.
- **Controller is authoritative** for the live session ID.
- Recorder starts/resumes using controller ID and controller sessionStart.

### Recovery
- Recovery must never silently resume recording.
- Recovery state is **paused** until user explicitly chooses Resume.
- Resume prompt must be single-shot and non-reentrant.

### Pause semantics
- Paused time must not be counted toward elapsed duration.
- Distance must not increase while paused.
- UI must remain responsive during pause and recovery (ticker/updates allowed).

### Observability
- Critical state transitions should be logged (start, pause, resume, finalize, recover).
- Any “gap” in GPS fixes should be detectable and labelable (stall signals allowed).

## Non-goals (for now)
- Background reliability across OEM battery killers is not guaranteed yet.
- Auto-pause heuristics are not enforced yet.
