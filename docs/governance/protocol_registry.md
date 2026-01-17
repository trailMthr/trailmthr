# Governance Protocol Registry

## Purpose

This registry records protocols that are explicitly recognized as compatible with TrailMthr governance philosophy.

Its purpose is to:

* Provide a clear source of truth for sanctioned protocols
* Preserve founder intent and philosophical constraints
* Prevent silent value drift or informal adoption
* Make protocol legitimacy auditable over time

In TrailMthr, **protocols derive authority from philosophy**, not the reverse.

---

## Active Protocols

### Constrained Matchmaking Protocol

**Status:** Active · Sanctioned

**Philosophy Anchor:**

* `docs/governance/philosophy/constrained_alignment_principle.md`

**Protocol Specification:**

* `docs/protocols/constrained_matchmaking_protocol.md`

**Scope of Application:**

* Human matching and role alignment
* Community participation and collaboration
* Hiring and professional evaluation
* Mentorship and guidance
* Governance and stewardship roles
* Safety- and trust-sensitive environments

**Non-Negotiables (Inherited):**

* Voluntary participation
* Explicit resolution preference
* Dignity of exit
* Contextual trust (no global reputation score)
* System warnings permitted; coercion forbidden

Any implementation that violates its philosophy anchor is considered **incompatible with TrailMthr governance**, regardless of technical correctness or adoption.

---

## Registry Governance

* This document may be appended as new protocols are introduced
* Removal or modification of an entry requires explicit justification
* Protocols not listed here are considered experimental or unofficial

This registry exists to make TrailMthr’s internal logic legible to future maintainers, contributors, and communities.

---

## Governance Cross-Reference

The principles defined in this document are formally operationalized through TrailMthr governance.

* **Protocol Registry:** `docs/governance/protocol_registry.md`
* **Primary Protocol Implementation:** `docs/protocols/constrained_matchmaking_protocol.md`

Any protocol claiming compatibility with this philosophy must be listed in the registry and remain subordinate to the Constrained Alignment Principle.
