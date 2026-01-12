# Constitutional Change Process (Change Without Capture)

## Principle

Governance changes are slow by design.
No single form of legitimacy may alter governance.

Constitutional change requires multiple independent constraints to agree.

## What Counts as Constitutional

Any change that alters:
- the Governance Canon
- Non-Punitive Enforcement Doctrine
- Capability Model
- Constitutional Change Process itself
- Perpetuity Threat Model
- definitions of refusal/amplification/forkability

## Change State Machine (Required)

A constitutional change MUST traverse these states in order:

1. PROPOSED
2. OBSERVED (public discussion + time in open state)
3. REPLICATED (independent implementations or validations exist)
4. MEASURED (non-degradation evidence exists)
5. ELIGIBLE (meets all gates)
6. ACTIVATED (reversible rollout)
7. LOCKED (rare; only with explicit additional gates)

No skipping states.

## Mandatory Gates

A proposal MUST satisfy all gates:

- **Time persistence:** minimum time between states (prevents sudden capture)
- **Independent replication:** at least two independent confirmations/implementations
- **Non-degradation metrics:** evidence that core invariants are not harmed
- **Audit trail:** append-only record of discussion + evidence + rule versions
- **Reversible rollout:** ability to revert without special authority

## Forbidden Paths

- emergency powers
- simple majority votes as sole gate
- founder vetoes or council vetoes
- private decision-making
- “temporary” exceptions without state-machine record

## The “Locked” State

LOCKED is reserved for constraints that, if changed rapidly, enable capture.
LOCKED requires additional time persistence and replication beyond ACTIVATED.

LOCKED should be rare.
Most changes should remain reversible by design.
