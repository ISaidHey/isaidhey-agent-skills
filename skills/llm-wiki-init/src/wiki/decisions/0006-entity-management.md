---
type: decision
id: "0006"
title: "Entity management: creation, resolution, and boundaries"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
Entity pages are the nodes of the knowledge graph — they enable mention density tracking, contribution scope, and hub navigation. Without clear rules for when to create them, how to resolve names, and what counts as an entity, the graph either misses connections or fills with noise.

## Decision
**Every real person mentioned in wiki output gets an entity page in `wiki/entities/` and a `[[wikilink]]` at every mention. Name resolution is exact full-name only. Edge cases — opt-outs, aliases, illustrative names, credits lists — have explicit rules.**

**Creation:** entity page for every real person (authors, subjects, any reference). No skipping for "minor" mentions. Entity pages also cover places, organizations, named objects, and any noun consistently referred to by a specific proper name.

**Resolution:** exact full-name matching only. `Jane Smith` matches `jane-smith.md` only. For alias lookup, use exact phrase match against `aka` fields — only for full names (≥2 words); single-word names skip lookup. Resolution ladder: (1) exact `title` match → merge without confirmation; (2) exact `aka` phrase match (full name, ≥2 words) + attended → show match, ask user; (3) exact `aka` phrase match + unattended → merge, set `confirmed: false`; (4) single-word name or no match → new entity, ask if attended, `confirmed: false` if unattended.

**Opt-out:** create page with `opted_out: true`; leave content blank. Page exists for graph linkage only — removing it breaks wikilinks across the vault.

**Aliases:** `aka: []` in entity frontmatter holds nicknames and alternate names. Resolve nicknames by running `rg` on `wiki/entities/` for matching `aka` values. Unknown aliases → `> [!NOTE] Unresolved alias`. A separate `wiki/aliases.md` index was considered and rejected — it is derived data that drifts from frontmatter.

**Illustrative names:** names used only in source examples (e.g., "Pete," "Beth" in a rulebook trade demo) — do not create entity pages. They are not real entities.

**Credits lists:** do not bulk-create entities from credits sections. Only create entity pages for primary authors or designers directly attributed to the source's content.

## Consequences
Wikilinks enable mention density tracking and contribution scope across the wiki. People pages become hubs for cross-wiki involvement tracking. `confirmed: false` accumulates as debt if not resolved. **Attended vs unattended:** ingest is attended when invoked interactively in Claude Code with a human present. Ingest is unattended when run via a scheduled/cron context or explicitly signaled (e.g., `--unattended`). Default assumption: attended. A first-time user of this template will always be in attended mode. **Re-evaluate if:** mention volume creates an unmanageable entity page count, or `confirmed: false` debt becomes significant.

## Invariants
- Do not use plain text names without wikilinks in wiki pages
- Do not implement fuzzy name matching; do not auto-merge entities without confirmation
- Do not delete opted-out entity pages; do not fill content for opted-out entities
- Always resolve to canonical page slug — never link to an alias slug
- Do not reintroduce a separate aliases index file
- Do not bulk-create entities from credits sections
