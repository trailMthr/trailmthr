# Contract Protocol

> This document defines how contracts are issued, evaluated, accepted, and enforced within the system.
>
> Contracts are not law.
> Contracts are explicit, voluntary commitments with defined scope, risk, and stewardship obligations.
>
> This protocol exists to prevent silent obligation, hidden authority, and accidental harm.

---

## 1. Purpose

The Contract Protocol ensures that:

* commitments are entered knowingly and voluntarily
* obligations are explicit and inspectable
* stewardship of others’ property, data, safety, and experience is preserved
* systems never rely on implied consent
* harm is addressed through refusal and constraint, not punishment

Contracts are designed to **block the psychological transition from person to object** by enforcing clarity at the moment of agreement.

---

## 2. Definitions

**Contract**
A structured, typed commitment between parties that defines scope, obligations, permissions, risks, duration, and exit conditions.

**Issuer**
The entity offering a contract.

**Acceptor**
The entity voluntarily agreeing to a contract.

**Beneficiary**
An entity whose interests, property, data, or safety are protected by the contract.

**Stewardship**
Temporary, scoped responsibility over something that belongs to others. Stewardship never implies ownership.

**Admissibility**
Whether a contract is allowed to exist within the system based on governance constraints.

**Refusal**
A non-punitive system response where an action or contract is not accepted, propagated, or amplified.

---

## 3. Core Principles

* All contracts are opt-in.
* Silence is never consent.
* All obligations must be explicit.
* All permissions are stewardship permissions.
* All contracts are bounded in scope and time.
* All contracts must allow exit.
* All enforcement is observable and auditable.

---

## 4. Contract Lifecycle

1. **Drafted** – contract text and structure are proposed
2. **Analyzed** – system checks syntax and completeness
3. **Admissibility Checked** – governance constraints are applied
4. **Presented** – human-readable summary is shown
5. **Accepted** – explicit acknowledgment is recorded
6. **Active** – contract governs behavior within scope
7. **Expired / Exited** – contract ends automatically or by choice

No contract may skip stages.

---

## 5. Required Contract Fields (Completeness Rules)

A contract MUST define all of the following to be eligible for acceptance:

### 5.1 Parties

* Issuer
* Acceptor
* Optional: Beneficiaries

### 5.2 Scope

* domain or context the contract applies to
* objects or resources affected
* explicit exclusions

### 5.3 Obligations

* written as explicit verbs
* bounded to scope
* must not require implicit interpretation

Examples:

* “Call hazards when leading a group run.”
* “Do not share others’ location outside the group.”

### 5.4 Permissions

* narrow and single-purpose
* explicitly stewardship-based
* must not grant authority beyond scope

### 5.5 Risks

* physical risks (if applicable)
* data or privacy risks
* social or coordination risks
* explicit statement of what the system does NOT guarantee

### 5.6 Duration and Expiry

* start condition or time
* end time or event
* default expiry if not renewed

### 5.7 Exit Conditions

* how an acceptor may leave
* how an issuer may terminate
* what happens to shared data on exit

### 5.8 Dispute and Incident Handling

* non-punitive process
* refusal and constraint mechanisms
* auditability of outcomes

### 5.9 Audit Metadata

* contract identifier
* version
* acceptance timestamp
* governing rule version

If any required field is missing, the contract MUST be refused.

---

## 6. Admissibility Rules (System-Prescribed Constraints)

Even if complete, a contract MUST be refused if it contains:

* punishment clauses (bans, penalties, shaming)
* irreversible obligations
* hidden or discretionary authority
* coercive identity or account requirements
* non-audited enforcement paths
* permissions not tied to explicit scope

A contract MUST include:

* explicit exit rights
* explicit risk acknowledgment
* explicit refusal-based enforcement language

---

## 7. Contract Presentation (Awareness Requirements)

Before acceptance, the system MUST present:

### 7.1 Summary View

* primary obligation(s)
* primary permission(s)
* primary risk(s)

Limited to what a human can reasonably understand at a glance.

### 7.2 Full Structured Text

* inspectable
* versioned
* unchanged from what will govern behavior

### 7.3 Explicit Acknowledgment

Acceptance requires affirmative acknowledgment of key obligations and risks.

Scroll-based or implicit acceptance is forbidden.

---

## 8. Stewardship Doctrine

All permissions granted by contracts are stewardship permissions.

This means:

* actions must be reversible where possible
* actions must be logged
* actions must be scoped
* actions must prioritize beneficiaries over issuers

Ownership claims are forbidden.

---

## 9. Enforcement Model

Contracts are enforced through:

* refusal of non-compliant actions
* constraint of permissions
* automatic expiry

Contracts are NOT enforced through:

* punishment
* shaming
* secret moderation
* discretionary overrides

---

## 10. Relationship to Governance Canon

This protocol is subordinate to:

* Governance Canon
* Non-Punitive Enforcement Doctrine
* Capability Model
* Constitutional Change Process

Any change to this protocol is a constitutional change.

---

## Closing Statement

Contracts exist to make obligations visible at the moment they matter.

A system that requires trust without clarity is already unsafe.

This protocol ensures that no one can claim ignorance, and no one is forced into responsibility without consent.
