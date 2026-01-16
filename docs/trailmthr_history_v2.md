# TrailMthr History Log (Living Document)

> **Purpose:** A durable, repo-friendly history of TrailMthr that records **why** decisions were made, not just what changed.  
> Earlier history is intentionally **condensed and paraphrased**.  
> New and future entries are **precise, evidence-backed, and exact**.

> **Recommended repo path:** `docs/trailmthr_history.md`

---

## Canonical Principles (Non‑Negotiable)

1. **No lies. No ghosts. No silent failure.**
2. **Consent-first behavior.**
3. **Offline-first reliability.**
4. **Sovereignty & independence.**
5. **Separation of truth layers.**
6. **Monetization without coercion.**

---

## Roadmap Phases

- Phase 0 — Trust & Repo Integrity  
- Phase 1 — Core Loop Integrity  
- Phase 2 — Identity & Intelligence  
- Phase 3 — Community & Exchange  

---

# Timeline

## 2026‑01‑11 — Opt‑in Partner / Ads Model Locked

Promotional content may exist **only** on an intentionally visited Community page.  
No ambient ads. No feature gating. Only trusted, mutualistic partners.

---

## 2026‑01‑11 — Run Telemetry Verified

Evidence: `activity_1768072848692.jsonl`  
571 GPS fixes, ~1.5s cadence, ~3.36m accuracy, clean recovery from stall.

---

## 2026‑01‑10 — GPS Trust Milestone (Option B)

Screen‑off recording validated using foreground service + truthful notification model.

---

## 2026‑01‑08 → 2026‑01‑10 — Permissions Philosophy Locked

Rejected forced background permissions in favor of honest readiness checks.

---

## 2025‑12 — Early Direction (Condensed)

Offline‑first outdoor companion; mapping, activity tracking, ThinkSpace introduced.

---

## 2025‑12‑23 — Phase 0 Closed

Repo discipline, signed commits, architectural truth locked.

---

# Entry Policy

- Old history: condensed.
- New entries: exact and evidence‑based.

---

## 2026-01-15 — Phase 1 Core Loop: Force-close Recovery + Pause-safe Timer Stabilized

### What changed
- Unified live session identity: **LiveActivityController activityId is now authoritative**, recorder starts with `activityIdOverride` + `startTimeOverride`.
- Recovery UX stabilized:
  - Single resume prompt (no stacking / re-entrant dialogs).
  - Resume handshake order hardened (recorder stream reattaches before controller lifecycle flips).
- Timekeeping truth fixed:
  - Recorder duration mirrors controller `elapsed` (pause-aware, recovery-safe).
  - UI timer repaint after process death fixed by starting ticker during recovery + on resume.

### Bug symptoms eliminated
- Resume prompt not appearing after force-close (ID mismatch).
- Multiple resume prompts (re-entrant dialog race).
- Timer “freezing” after restart until user interaction (ticker not running post-recovery).

### Tests performed
- Start → pause/resume → finish (baseline).
- Start → force-close → reopen → resume (single prompt, continued tracking).
- Pause → force-close → reopen → resume (paused truth preserved).
- Verified: polyline continuity, distance continuity, pause-safe elapsed time, single resume prompt.

### Notes
- Debug JSONL logs confirmed GPS gating and point persistence remained stable during recovery scenarios.
