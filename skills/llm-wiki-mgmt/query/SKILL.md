---
name: query
description: Use when the user asks any question answerable from wiki knowledge, requests a lookup, comparison, or analysis of ingested material.
---

# Skill: Query

Answer a question from wiki content.

---

1. Read `wiki/index.md` to find relevant pages
2. Read those pages in full
3. Follow `[[wikilinks]]` to gather connected knowledge
4. Synthesize answer with `[[page]]` citations
5. If the answer yields a cross-domain insight meeting the analysis boundary, offer to file a new `wiki/analysis/` page. Per ADR-0011.
6. Append to log: `## [YYYY-MM-DD] query | Question summary`

## Common Mistakes

- Answering from training knowledge without reading wiki pages — all claims must be grounded in wiki content with `[[page]]` citations
- Not following `[[wikilinks]]` — a single page rarely has the full picture; traverse links to gather connected knowledge
- Offering an analysis page for a within-domain insight — ADR-0011 requires (a) the insight spans ≥2 distinct concept domains AND (b) the relationship between those domains is itself the core insight, not just topical overlap
- Reading many pages without narrowing scope first — `wiki/index.md` step 1 exists to identify which pages are actually relevant; don't read broadly and hope
