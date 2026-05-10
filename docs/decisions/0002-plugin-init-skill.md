---
type: decision
id: "0002"
title: "Automate plugin scaffolding with plugin-init skill"
status: active
date: 2026-05-10
superseded_by: ""
---

## Context

Creating Claude Code plugins has come up repeatedly — each requires `.claude-plugin/plugin.json` with correct schema, optional skill placeholders under `skills/`, and optional registration in a marketplace. Manual scaffolding is repetitive and error-prone, for the same reasons that drove `marketplace-init` (ADR 0001).

## Decision

**Build a `plugin-init` skill that scaffolds a Claude Code plugin directory via a guided multi-step flow: collect fields → create `plugin.json` → optionally add a skill placeholder → optionally register in a discovered marketplace → validate.**

Same two-file model as `marketplace-init`: `SKILL.md` orchestrates the conversation; `scripts/init.sh` handles all file I/O and emits a single JSON line on success. Three isolated functions (`create_plugin`, `create_skill`, `register_plugin`) are controlled by flags so flows can be split or reused independently in future.

The skill placeholder (`create_skill`) is intentionally minimal — name, description, `TODO` body only. Full skill authoring is delegated to `/superpowers:writing-skills`.

## Consequences

Easier: new plugins scaffolded correctly in one invocation; marketplace registration discovered automatically via `find`; `claude plugin validate` run automatically if CLI is present.

Harder: same runtime dependencies as `marketplace-init` (`jq`, GNU `realpath`). Skill placeholder is not a substitute for authored skill content — users must follow up with `/superpowers:writing-skills`.

**Re-evaluate if:** the wizard still requires significant manual cleanup after invocation — signals the flow needs refinement or the script's scope needs adjustment.

## Invariants

- All user-controlled values **must** be passed to `jq` via `--arg`, never string-interpolated into JSON — same constraint as ADR 0001.
- `plugin.json` writes **must** pre-check for existing file and abort — no silent overwrites.
- `marketplace.json` mutations **must** read → transform via `jq` → write; never in-place string edit.
- Name validation **must** use `^[a-z][a-z0-9]*(-[a-z0-9]+)*$` for both plugin and skill names.
