# Enforcement Contracts (Bridge Between Canon and Code)

## Purpose

These contracts define deterministic “if X then Y” behaviors.
They are written so they can later become tests.

They describe outcomes, not implementation.

---

## Contract EC-001 — Refusal Instead of Punishment

### Statement
If an action/data violates a defined constraint, the system MUST respond with **refusal** rather than punishment.

### Refusal Means
The system MAY:
- store the data for forensic/audit purposes
- mark it as non-propagating
- mark it as non-indexed
- remove or reduce its weight in ranking/trust

The system MUST NOT:
- ban an identity as a primary response
- silently delete the data
- allow privileged overrides without audit

### Audit Requirements
Every refusal MUST emit an append-only event containing:
- rule_version
- refusal_reason_code
- affected_object_id
- timestamp
- reversible flag

---

## Contract EC-002 — No Hidden Authority Paths

### Statement
No code path may bypass enforcement contracts based on role, identity, or “admin” status.

### Requirements
- All persistence writes must traverse a single enforcement gateway.
- Any exception MUST be encoded as a rule with audit trace and must still emit events.

---

## Contract EC-003 — Capability Expiry and Revocation

### Statement
Capabilities MUST expire and MUST be revocable by rule.

### Requirements
- A capability must have time bounds and/or usage bounds.
- Revocation triggers must be evidence-driven and deterministic.
- Issuance and revocation must be logged as append-only events.

---

## Contract EC-004 — Constitutional Change State Machine

### Statement
Any change labeled “constitutional” MUST follow the state machine.

### Requirements
- No direct activation from PROPOSED.
- Time gates must be enforced.
- Activation must be reversible unless explicitly locked.

---

## Contract EC-005 — Historical Record Integrity

### Statement
Governance and enforcement history MUST be append-only.

### Requirements
- No deletion of governance log entries.
- No rewriting past entries.
- Corrections are new entries referencing prior ones.
