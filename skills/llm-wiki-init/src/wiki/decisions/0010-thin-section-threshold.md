---
type: decision
id: "0010"
title: "Thin-section threshold for page creation"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
When ingesting a source, some sections contain too little content to warrant a standalone wiki page — they create graph noise and shallow pages that add navigation overhead without adding knowledge density. Without a threshold rule, ingesters make ad-hoc choices that produce inconsistent graph granularity.

## Decision
**Sections under 150 words with no sub-bullets and no code blocks are considered thin. Thin sections are merged into the nearest adjacent page rather than given a standalone page.**

During attended ingest: list each thin section with its word count and a one-line context summary, ask per-section whether to give it a standalone page or merge. Do not assume the same answer for all thin sections.

During unattended ingest: apply judgment per section — if the section is queryable as an independent unit, give it a standalone page; if it only makes sense alongside an adjacent section, merge.

## Options considered

### 100-word threshold (rejected)
Too aggressive — collapses sections that contain useful standalone facts. A 120-word concept definition would be merged when it warrants its own page.

### 200-word threshold (rejected)
Too conservative — allows genuinely thin content to proliferate as standalone pages. The graph fills with low-signal nodes.

### 150 words (chosen)
Covers a well-formed paragraph with a definition, a sentence of context, and a citation. Sections at this threshold can stand alone; sections below it typically cannot.

## Consequences
Graph stays dense and meaningful. Merged content is harder to locate if readers expect separate pages, but the wiki's query-based access pattern makes direct navigation less critical than knowledge density. **Re-evaluate if:** users consistently report difficulty locating merged content, or if analysis use cases require finer page granularity than the threshold allows.

## Invariants
- Apply threshold per-section, not per-source — a thin section in an otherwise long source still gets merged
- Do not apply threshold to source pages (`wiki/sources/`) — source summaries always get standalone pages regardless of length
- Never merge sections from different concept domains into a single page
