# Perpetuity Threat Model

## Purpose

This document lists the primary threats to long-term integrity and the required defensive posture.
It is not exhaustive; it is an evolving catalog with append-only history.

## Threats

### T1: Centralization via convenience
- “Just ship faster”
- “Let admins fix it”
- “We need a single source of truth”

### T2: Economic capture
- monetization pressure creates privileged pathways
- pay-to-amplify systems become hidden rulers

### T3: Narrative rewriting
- selective history
- “official story” replacing record

### T4: Silent scope creep
- enforcement drift
- exceptions becoming norms

### T5: Identity coercion
- forcing accounts, KYC, real names, or social linking
- turning participation into permission

## Required Defensive Posture

- Forkability preserved at all times
- Audit trails are append-only and queryable
- No single dependency is required to operate
- Capabilities remain narrow and revocable
- Refusal replaces punishment

## Failure Conditions

TrailMthr is considered failed if:
- users cannot exit with their data without material loss
- history can be erased or rewritten
- enforcement can occur without an auditable trace
- privileged actors can bypass constraints
