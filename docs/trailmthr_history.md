# TrailMthr History Log (Living Document)

> **Purpose:** A durable, repo-friendly changelog of TrailMthr milestones, architectural pivots, philosophical direction changes, and “trust moments.”  
> **Recommended repo path:** `docs/trailmthr_history.md`  
> **Note on accuracy:** Entries below are reconstructed from our conversations and may be incomplete; treat them as a *living* timeline to refine as the codebase evolves.

---

## Core Principles (Canon)

1. **No lies. No ghosts. No silent failure.** If something stops working (GPS fixes stall, permissions missing), TrailMthr must *say so*.
2. **Consent-first system behavior.** Nothing gets pushed into a user’s life (calendar, sharing, automation) without explicit user intent.
3. **Offline-first reliability.** The app remains useful without network connectivity and should degrade gracefully.
4. **Sovereignty-minded architecture.** Prefer modular, open, portable approaches; avoid dependence on scrape-restricted or lock-in services.
5. **Separation of concerns.** Telemetry (debug logs) is not the same as canonical user history (activity DB).
6. **Monetize without coercion.** No ad gating, no ambient ads, no attention hijacking; any promotion must be intentional and aligned.

---

## Roadmap Phases (High-level)

- **Phase 0 — Trust & Repo Integrity:** reproducible build, clean repo hygiene, branch discipline, architectural truth written down.
- **Phase 1 — Core Loop Integrity:** start → pause/resume → stop → persist → recover, with *boring* reliability.
- **Phase 2 — Identity & Intelligence:** ThinkSpace, TrekMaster, Health AI foundations; data model maturity; exports/imports.
- **Phase 3 — Community & Exchange:** events, groups, mutual aid, and opt-in partners (no ads in core tools).

---

# Timeline

## 2026-01-11 — Opt-in Partners / Ads Philosophy Locked (Phase 3 Community)

**Decision:** TrailMthr may include promotional content only under strict constraints:
- Ads/promotions must live on a **separate page** the user **intentionally navigates to** (likely **Community** tab).
- Users **never see ads while using tools** (Map, Recording, ThinkSpace, TrekMaster, etc.).
- **No ad gating**: no feature, export, or capability requires viewing ads.
- Only products/services Jonathan **personally believes in** with a **mutualistic** relationship.
- No dark patterns; no “attention economy” mechanics.

**Why this matters:** Preserves trust and sovereignty while allowing sustainable revenue paths that do not distort product incentives.

---

## 2026-01-11 — Run-mode Telemetry Confirmed (Screen-off + Wi‑Fi off)

**Artifact analyzed:** `activity_1768072848692.jsonl` (DebugLogger JSONL)
- Event counts: 575 total; **571 `gps_fix`**
- Avg fix cadence: ~**1.5s**; max gap ~**2.0s**
- Avg accuracy: ~**3.36m**
- One stall state event detected and recovered
- Final distance logged: ~**1350m** (~**0.84mi**) consistent with field report

**Interpretation:** Foreground-service GPS pipeline is healthy under real constraints (screen off majority, Wi‑Fi off). Remaining differences vs Garmin are *calibration* (micro-jitter), not lifecycle failure.

---

## 2026-01-10 — GPS Recording Trust Milestone (Option B)

**Milestone:** Screen-off recording is *trustworthy* using Android Foreground Service + persistent notification + stall detection.

**What changed / locked in**
- Adopted **Option B** philosophy: *no forcing*; do not require Background Location “Always” to function.
- Implemented/validated **truth model**: if fixes stop arriving, detect and surface **stalled** rather than pretending to record.
- Confirmed that **Wi‑Fi off** does not break GPS recording (Android 16 baseline device plan: Galaxy S25+).

**Field test (walk)**
- TrailMthr ≈ **0.84 mi** vs Garmin ≈ **0.81 mi** (~**+3.7%**)
- Screen off most of the walk; Wi‑Fi toggled off ~2 minutes in; checked around halfway then screen off again
- Interpretation: functioning system; remaining delta is **calibration**, not a background failure.

**Next tuning direction**
- Reduce micro-jitter accumulation via **mode thresholds** (e.g., non-zero `minDistM` for walk/run) while preserving responsiveness.

---

## 2026-01-08 to 2026-01-10 — Permissions & Foreground Notification Integrity

**Workstream:** Android permissions and the “don’t force our way” policy.
- Location permissions: fine/coarse (and background listed but not required for Option B baseline)
- Foreground service requirements for geolocator (Android 13+)
- Notification permission (Android 13+): request and enforce *truthfulness* (if notifications denied, recording should not claim it can run screen-off reliably)

**Outcome:** Recording readiness is defined by a pre-flight set of conditions (permissions + services + truthful notification channel).

---

## 2025-12-23 — Phase 0 Closed (Repo Trust / Discipline)

**Milestone:** Phase 0 officially closed — *stable build, clean commits, clean merge, clean push.*

**Declared truth**
- `master` represents reality, not hope
- repo hygiene + SSH auth + signed commits discipline
- architectural truth written down (states, transitions, principles)

**Phase 1 declared goal (non-negotiable)**
Open app → start activity → pause/resume → stop → persist → recover  
**No lies. No ghosts. No silent failure.**

---

# Key Architectural / Code Milestones (Grouped)

## Activity Loop & GPS Tracking
- Introduced a canonical **ActivityRecorder** with:
  - state stream (`RecorderState`) and lifecycle methods (start/pause/unpause/finishAndSave/stop)
  - trackpoint persistence via repository
  - per-mode thresholds (time/distance/accuracy gates)
- Added **DebugLogger** (JSONL per activity) to capture:
  - `activity_start`, `gps_fix`, `gps_stall_state`, `activity_end`
- Implemented **truth push** to UI/controller via distance updates
- Added stall detection concept (watchdog) to avoid “silent recording”

## ThinkSpace & TrailObjects
- Added ThinkSpace repository hooks to create TrailObjects like `activity_end` with payload metadata
- Direction: ThinkSpace as a deliberate, user-controlled layer (capture + interpret) rather than automatic life insertion

## Consent-first Calendar / AI
- Direction locked: no automated calendar insertion without explicit user intent; “multiple brains under a hub” for AI modules (Workout brain, TrekMaster brain, etc.)

## Open / Modular Strategy
- Direction: modular build, open data sources where possible, avoid scrape-restricted dependencies; plan for PCT use cases

---

# How to Add New Entries (Template)

Copy/paste:

## YYYY-MM-DD — <Title>

**What happened:**  
**Why it matters:**  
**Evidence / validation:** (test, logs, screenshots, metrics)  
**User impact:**  
**Follow-up:** (next steps, tuning decisions)

---

