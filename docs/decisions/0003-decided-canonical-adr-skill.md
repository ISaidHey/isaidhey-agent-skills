---
type: decision
id: "0003"
title: "decided as canonical cross-project ADR skill"
status: active
date: 2026-05-11
superseded_by: ""
responsible: "isaidhey"
accountable: "isaidhey"
---

## Context

The `decided` skill originated in Phandelver as a project-specific ADR documenter hardcoded to `wiki/decisions/`. It was subsequently ported to devcontainer-claudebot, generalizing the default path to `docs/decisions/`. When brought into `core-skills/` as a distributable skill, the opportunity arose to establish a canonical cross-project version — restoring features from the original (index management, Haiku relationship analysis, targeted lint) and adding context-first ADR directory discovery so it works seamlessly in any project.

## Decision drivers

- Cross-project portability — skill must work in any repo, not assume a fixed directory
- Feature parity with origin — Phandelver's index, relationship analysis, and lint are load-bearing, not optional
- Context-first discovery — leverage CLAUDE.md autoloading rather than probing filesystem unnecessarily
- Single canonical source — one version to maintain and distribute via marketplace

## Decision

**Chosen: establish `isaidhey:decided` as the canonical cross-project ADR skill, because it was the natural completion of a progression already underway — Phandelver → devcontainer-claudebot → core-skills — requiring only feature restoration and generalization to be shippable.**

## Options considered

No alternatives formally weighed — this was the natural next step in an existing progression.

## Consequences

What becomes easier or harder:
- Easier: any project gets a full-featured ADR workflow without per-project setup
- Easier: index + Haiku relationship analysis make ADR vaults navigable and self-linking
- Harder: small agent overhead per new decision (Haiku subagent invocation)

**Re-evaluate if:** relationship analysis proves too noisy or costly in practice, or ADR dir discovery needs to support non-CLAUDE.md config conventions.

## Confirmation

- Skill in use produces well-formed ADR files with all required frontmatter fields
- `index.md` present and updated after each write
- `## ADR Directory` section appears in `CLAUDE.md` after first run in a new project
- `## References` section appears in new ADRs when relationships exist

## Invariants

- ADR dir discovery must check context before probing filesystem
- ADR dir must be persisted to project config after first discovery
- Index must be updated on every status change — new, supersede, retire, reject
- All bash scripts must use the resolved `<ADR_DIR>` — never hardcode a path

## References

Related:
- [[0001-marketplace-init-skill]] — both establish distributable skills in core-skills plugin; 0003 elevates the pattern of feature-rich, cross-project skills that 0001 pioneered
- [[0002-plugin-init-skill]] — both are foundational scaffolding skills in the same plugin; 0003's context-first discovery pattern complements plugin-init's multi-step workflow design
