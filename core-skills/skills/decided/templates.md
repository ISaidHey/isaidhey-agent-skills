# ADR Templates

## Simple

For: clear decision, low complexity, few/no alternatives.

```markdown
---
type: decision
id: "0042"
title: "Short decision title"
status: proposed
date: YYYY-MM-DD
superseded_by: ""
---

## Context
What situation or constraint led to this?

## Decision
**One sentence. Bold. What was decided.**

## Consequences
What becomes easier or harder. **Re-evaluate if:** [condition].

## Invariants
Load-bearing constraints any superseding decision must explicitly address — either preserve or consciously override with justification.
```

## Full

For: multiple options weighed, significant consequences, worth capturing the full reasoning trail.

```markdown
---
type: decision
id: "0042"
title: "Short decision title"
status: proposed
date: YYYY-MM-DD
superseded_by: ""
responsible: ""   # does the work
accountable: ""   # owns the outcome, final sign-off
consulted: ""     # two-way input sought
informed: ""      # one-way, kept in the loop
---

## Context
What situation or constraint led to this? What problem is it solving?

## Decision drivers
- [force, constraint, or desired quality]
- [another driver]

## Decision
**Chosen: "[Option A]", because [one-sentence justification].**

## Options considered

### Option A (chosen)
- Good: …
- Bad: …

### Option B
- Good: …
- Bad: why rejected

## Consequences
What becomes easier or harder. **Re-evaluate if:** [condition].

## Confirmation
How to verify this decision is being followed — automated checks, code review criteria, fitness functions, or architectural tests. Omit if not applicable.

## Invariants
Load-bearing constraints any superseding decision must explicitly address — either preserve or consciously override with justification.
```
