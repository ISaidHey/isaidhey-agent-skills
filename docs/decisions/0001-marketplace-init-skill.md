---
type: decision
id: "0001"
title: "Automate marketplace scaffolding with marketplace-init skill"
status: proposed
date: 2026-05-10
superseded_by: ""
---

## Context

Creating Claude Code plugin marketplaces has come up multiple times across different contexts — team skills, internal devcontainer skills, personal skills. Manual scaffolding (creating `.claude-plugin/marketplace.json`, the directory structure, getting all required fields right) is repetitive and error-prone. This was also undertaken as an educational exercise in skill authoring.

## Decision

**Build a `marketplace-init` skill in the `isaidhey-agent-skills` plugin that scaffolds a Claude Code marketplace via an interactive wizard.**

## Consequences

Easier: adding a new marketplace should be as simple as invoking the skill and answering prompts — no manual file creation or schema lookup required.

Harder: nothing structurally harder; the skill adds a dependency on `isaidhey-agent-skills` being installed.

**Re-evaluate if:** invoking the skill still requires as much manual tweaking afterward as doing it by hand — that signals the wizard needs refinement or the approach needs reassessment.

## Invariants

None defined at this time.
