---
type: decision
id: "0007"
title: "Topic namespacing: subdirectory thresholds"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
As wiki pages accumulate for a topic domain, flat directories become hard to navigate. Topic subdirectories solve this, but applying a single threshold treats named products and generic topics identically. Named products are bounded, self-referential domains — they warrant namespace isolation at smaller scale than generic open-ended topics.

## Decision
**Named product/brand/game: 3+ concept pages → create `wiki/concepts/<topic>/`. Generic topic: 4+ pages → create `wiki/concepts/<topic>/`. Short filenames inside; wikilinks use `[[topic/page-name]]` form.**

Entity subdirs follow the same thresholds for entity pages within a domain.

## Consequences
Named products get namespacing at smaller scale without waiting for 4 pages. Generic topics maintain the higher threshold to avoid subdir sprawl. Short filenames inside subdirs keep wikilinks readable. **Re-evaluate if:** named product ingests are rare enough that the lower threshold adds overhead without value.

## Invariants
- Do not apply the 4+ generic threshold to named products/brands/games
- Do not flatten existing topic subdirs back to the parent dir once established
- Use `[[topic/page-name]]` short form in wikilinks — not full paths
