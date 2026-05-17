---
type: decision
id: "0002"
title: "Vault structure and special files"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
The vault is an intake→analysis→query pipeline, not a personal note system. It needs unambiguous directory semantics for each pipeline role, a stable set of persistent files for LLM session-start context reconstruction, and an index format that is easy to maintain programmatically on every ingest.

## Decision
**Vault root contains `capture.md` (human intake inbox), `raw/` (source file drop zone), and `wiki/` (LLM analysis output). No PARA directories.**

Directory roles:
- `capture.md` — at vault root; human appends entries, LLM strikes through after processing; lives at root (not inside `wiki/`) because `wiki/` is LLM territory
- `raw/` — human-dropped source files; immutable to LLM; named `raw/` not `sources/` to avoid collision with `wiki/sources/`
- `wiki/sources/` — LLM-written summary pages, one per ingested source
- `wiki/analysis/` — cross-source analysis, comparisons, discovered connections
- `wiki/entities/` — proper nouns: people, places, organizations, named objects
- `wiki/concepts/` — ideas, themes, frameworks
- `wiki/decisions/` — architectural decision records

**Four locations are permanent and non-mergeable:** `wiki/index.md` (content catalog), `wiki/log.md` (append-only record), `wiki/decisions/` (decision records directory), `capture.md` (handoff inbox at vault root). LLM reads log tail and recent frontmatter dates at session start to rebuild context efficiently.

**`wiki/index.md` uses `- [[path]] — summary` list entries under `## Sources` / `## Entities` / `## Concepts` / `## Analysis` section headers.** List format chosen over table: easier to upsert programmatically — find the section, insert a line, no column alignment required.

## Consequences
Clean separation between human input and LLM analysis. Naming makes purpose unambiguous. List-format index supports easy upserts on every ingest. **Re-evaluate if:** vault users shift to personal note-taking alongside the pipeline, or vault structure is significantly reorganized.

## Invariants
- Do not add PARA dirs anywhere in the vault
- Do not move `capture.md` inside `wiki/`
- Do not rename `raw/` to `sources/` — naming collision with `wiki/sources/`
- Do not rename `wiki/analysis/` — the analysis boundary is defined in ADR-0011
- Do not remove or rename the four permanent locations; do not merge them
- Do not revert `wiki/index.md` to table format
