---
type: decision
id: "0011"
title: "Analysis vs concept page boundary"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
Both `wiki/concepts/` and `wiki/analysis/` hold wiki knowledge. Without a clear boundary, ingesters make inconsistent choices: cross-cutting content ends up in concepts when it should be analysis, or analysis pages proliferate for content that belongs in a focused concept page.

Three separate operational places (ADR-0004, ingest/SKILL, query/SKILL) referenced analysis pages with vague triggers — "cross-cutting insights", "valuable analysis", "discovered connections" — without defining what qualifies.

## Decision
**A analysis page is warranted when (a) the insight spans ≥2 distinct concept domains AND (b) the relationship between those domains is itself the core insight — not just shared topic area.**

A concept page is used when knowledge belongs to one domain, even if it references entities or concepts from others.

Examples:
- "Transformer attention and human working memory share capacity constraints" → analysis (two domains: ML architecture, cognitive science; the parallel is the insight)
- "How transformer attention works" → concept (one domain: ML architecture)
- "Concordia game mechanics" → concept (one domain: Concordia)
- "Board game mechanics that parallel economic theory" → analysis (two domains: game design, economics; the parallel is the insight)

## Consequences
`wiki/analysis/` stays sparse and high-value. Cross-domain insights surface as first-class pages rather than buried in concept pages. **Re-evaluate if:** analysis pages are rarely created (threshold too high — lower to 1 domain minimum or broaden "relationship is the insight"); or analysis pages accumulate without clear value (threshold too low — raise requirement).

## Invariants
- Do not create analysis pages for content that belongs to a single domain
- The relationship between domains must be the insight — not just topical co-occurrence
- Query-generated analysis pages follow the same rule as ingest-generated ones
