---
type: decision
id: "0008"
title: "AI contract and tooling defaults"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
This vault uses Claude Code as its primary AI. Claude Code auto-loads `CLAUDE.md` at session start. Supporting multiple AI tools from a single instruction source adds cross-tool compatibility overhead on every vault change. Schema and conventions loaded unconditionally on every session inflate startup context.

Agents and skills need a consistent local file search tool. `rg` (ripgrep) is faster than `grep`, respects `.gitignore` by default, skips binary files, and has saner defaults for codebase search.

## Decision
**`CLAUDE.md` is the sole AI contract for this vault. Schema, conventions, and tooling rules live in `.claude/rules/` as path-scoped files that load only when matching files are opened.**

**Use `rg` for all local file searches in agent instructions, skills, and operational files.**

`grep` remains valid for filtering piped stdin (e.g., `command | grep pattern`) where no file path is involved — that is not a file search and not a violation.

## Consequences
Simpler: one file to maintain, no cross-tool compatibility overhead, minimal session startup context. `rg` must be installed in the execution environment.

Harder: reintroducing any non-Claude-Code AI tool would require building its instruction source from scratch.

**Re-evaluate if:** a second AI tool becomes actively used in this vault, or a target environment lacks `rg` and installing it is not feasible.

## Invariants
- `CLAUDE.md` is the single source of truth — do not add a parallel instruction file (AGENTS.md, GEMINI.md, etc.) without superseding this ADR
- Schema and conventions belong in `.claude/rules/` with path scoping — do not expand `CLAUDE.md` body to compensate
- New vault-wide rules go in `.claude/rules/` as separate files, not appended to `CLAUDE.md`
- Any new agent instructions or skills that search files must use `rg`, not `grep`
