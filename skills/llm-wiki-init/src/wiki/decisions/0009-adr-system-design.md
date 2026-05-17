---
type: decision
id: "0009"
title: "ADR system design"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
Decision records need per-decision metadata: status lifecycle (proposed / active / superseded / retired), supersession tracking via wikilinks, and RACI accountability. YAML frontmatter is document-level — a single file with multiple decision blocks cannot carry per-decision metadata.

Cross-references between ADRs need a canonical format so automated tooling produces consistent output and so ADRs are scannable without special tooling. Without a directionality rule, authors make inconsistent choices about back-patching older ADRs.

## Decision
**One file per ADR with YAML frontmatter. `wiki/decisions/index.md` maintained on every write.**

**Cross-references use a grouped `## References` section** (after `## Invariants`) with prose headers per relationship type. Canonical labels: `Supersedes:` · `Extends (does not supersede):` · `Related:` · `Contradicts:`. Each entry: `- [[NNNN-slug]] — one-clause reason`. Empty groups omitted.

The decision skill normalizes Haiku agent output to these canonical labels before writing: `related-to` → `Related:`, `supersedes` → `Supersedes:`, `extends` → `Extends (does not supersede):`, `contradicts` → `Contradicts:`.

**Cross-references are one-directional:** the newer ADR links to the older one; the older ADR is never back-patched. Forward discoverability is handled by search (`rg "0003"`) or tooling — not by content maintenance.

Lifecycle:
```
proposed → active → superseded | retired
         ↘ rejected
```

## Consequences
Frontmatter fields (status, date) are queryable per decision. `superseded_by` wikilinks create navigable chains. Older ADRs remain stable after publication. `## References` sections are consistently formatted for automated writing and reading. **Re-evaluate if:** decision volume is low enough that per-file overhead exceeds benefit, or a graph-query tool requires bidirectional edges.

## Invariants
- Decisions are never silently edited — changes require creating a superseding file; never delete old decisions
- `wiki/decisions/index.md` must be updated on every decision write
- `## References` section is always last; groups omitted when empty
- Never edit a published ADR's `## References` section to add a back-link to a newer ADR
