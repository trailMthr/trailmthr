# Capability Model (Power Without Positions)

## Principle

There are no roles.
Only capabilities.

A capability is narrow, bounded, and revocable by rule.

## Capability Properties (Required)

Every capability MUST have:
- **scope** (what it can touch)
- **purpose** (single responsibility)
- **bounds** (time-limited and/or usage-limited)
- **provenance** (what evidence triggered issuance)
- **revocation conditions** (automatic)

## Forbidden Properties

A capability MUST NOT:
- be permanent by default
- modify governance rules
- self-replicate
- be stackable into an admin-equivalent
- be granted based on status, identity, or persuasion

## Examples (Conceptual)

- validate trail geometry
- propose schema changes
- contribute trust signals (not assign trust)
- perform limited data curation within strict scope

## Revocation

Revocation MUST be automatic when:
- evidence quality degrades
- conflict rate rises above thresholds
- time/usage bounds expire
- anomalous patterns are detected (as defined by rules)

No votes.
No discretion.

## Audit Requirement

Capability issuance and revocation MUST produce append-only events:
- capability_id
- subject (what entity held it)
- rule_version
- evidence summary
- timestamps
