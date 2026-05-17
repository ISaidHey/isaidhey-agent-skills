---
type: decision
id: "0012"
title: "Workstream ingest strategy"
status: active
date: 2026-05-09
superseded_by: ""
---

## Context

The vault needed a strategy for ingesting content from distinct knowledge domains (e.g. work projects, research papers, and personal interests) without context bleed between domains. The core tension: isolation vs. cross-domain discovery. Multiple options were evaluated during an attended brainstorm session before ingesting content as the first a domain workstream.

A secondary question was how granular to make concept pages — whether to mirror doc structure (one page per source page) or break further (one page per section).

## Decision drivers

- Query isolation: a Claude instance pointed at one page should get focused, non-polluted context
- Cross-domain serendipity: unexpected connections between domains have value; hard splits kill this
- Focused context injection: "easier to build context than to strip it"
- Traceability: every claim traceable to its source
- Scalability: strategy must work as the vault grows to many workstreams

## Decision

**Chosen: Single vault with `workstream` + `tags` for domain separation, section-per-page concept granularity, combined source page per multi-doc set, and `_index.md` per subdirectory.**

## Options considered

### Option A: Multiple vaults (rejected)

One vault per knowledge domain (e.g. `vault-domain-a/`, `vault-domain-b/`).

- Good: total isolation; no risk of context bleed
- Bad: kills cross-domain discovery; duplicates tooling; "which vault has X?" problem; PKM value is unexpected connections

### Option B: Single vault, no domain structure (rejected)

One vault, flat tags only, no workstream field.

- Good: simplest
- Bad: full-text/keyword queries produce noise across domains; no way to filter by domain programmatically

### Option C: Single vault + workstream field + namespaced subdirectories (chosen)

One vault; `workstream: <domain>` frontmatter on every page; concepts in `wiki/concepts/<domain>/`; entities in `wiki/entities/<domain>/`; query skill can filter by workstream tag.

- Good: cross-domain links preserved; workstream field enables programmatic filtering; subdirectories provide namespace without hard isolation; Obsidian shortest-path wikilinks still resolve correctly
- Bad: requires discipline on frontmatter; slightly more complex ingest

### Section granularity — theme clusters (rejected)

Group related sections into thematic concept pages (~5–6 pages per doc).

- Good: fewer pages; less cross-referencing
- Bad: pages grow large; defeats focused context injection goal

### Section granularity — two-tier gateway + sections (rejected)

One gateway page per source doc + section pages for rich content only.

- Good: entry point for broad queries
- Bad: redundancy between gateway and section pages; maintenance overhead

### Section granularity — section-per-page (chosen)

Every major section of a source doc becomes its own concept page. Thin sections handled per process (see Consequences).

- Good: maximum focus; easy to inject exactly one concept; directly serves "point an instance at one thing" goal
- Bad: many pages; some cross-references needed between related concepts

## Consequences

- Ingest produces more pages per source (20–25 for a 3-doc set vs 3–6 for page-per-doc approaches)
- `_index.md` required per subdirectory workstream — flat table of all pages + one-liners for discoverability without relying solely on `rg`/find
- Thin section handling becomes a process step: attended sessions ask per-section (standalone vs merge into adjacent); unattended sessions judge by queryability
- Named product features get entity pages under `wiki/entities/<domain>/` — treated same as org entities
- Combined source page used for multi-doc sets to avoid source fragmentation
- Tags `[workstream-slug, ...]` on every concept page enable query filtering even without subdirectory navigation

**Re-evaluate if:** query skill gains semantic/embedding retrieval (context-aware retrieval may make domain filtering less necessary), or vault grows to 10+ workstreams with significant cross-domain noise.

## Confirmation

- Every page in a workstream has `workstream: <domain>` frontmatter
- Every concept subdirectory has `_index.md`
- Thin sections confirmed with user before ingest (attended) or judged by queryability (unattended)
- `wiki/index.md` and `wiki/log.md` updated on every ingest

## Invariants

- Single vault is preserved — do not split into per-domain vaults without superseding this ADR
- `workstream` field is the canonical domain separator — do not introduce a competing field for the same purpose
- Section-per-page is the default granularity — theme clusters or page-per-doc require explicit justification and supersession
- Thin section decisions are deliberate — never silently merge or silently standalone; the process step must run

## References

Extends (does not supersede):
- [[0002-vault-structure-special-files]] — adds workstream-namespaced subdirs (`wiki/concepts/<domain>/`, `wiki/entities/<domain>/`) and extends the indexing pattern with `_index.md` per subdirectory
- [[0006-entity-management]] — named product features treated as entities; placed under `wiki/entities/<domain>/` per entity rules
- [[0007-topic-namespacing]] — workstream ingest applies existing subdirectory threshold rules to domain-scoped content
