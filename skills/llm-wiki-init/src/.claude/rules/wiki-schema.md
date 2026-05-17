---
paths:
  - "wiki/**/*.md"
---

# Wiki Frontmatter Schema

## Base schema

Every wiki page:

```yaml
---
title: 
tags: []
type: concept
status: active
workstream: 
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: 0
---
```

**type:** `concept` · `entity` · `source` · `index` · `analysis`

**status:** `active` · `reference` · `archived`

| Page type | `active` | `reference` | `archived` |
|-----------|----------|-------------|------------|
| concept | In regular use | Stable, unlikely to change | No longer relevant |
| entity | Currently referenced in sources | N/A — use `active` | No longer referenced in any source |
| source | N/A — use `reference` | Ingested and stable | Outdated or superseded source |
| analysis | Current working insight | Stable, unlikely to change | Superseded by newer analysis |

Always update `updated` when modifying a page. Increment `sources` when a new source contributes.

## Entity pages

Proper nouns — people, places, orgs, named objects, named game pieces, any noun consistently referred to by a specific proper name:

```yaml
---
title: Full Name
tags: []
type: entity
status: active
confirmed: true
opted_out: false
aka: []
workstream: 
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: 0
---
```

`confirmed: true` — name unambiguously matched. `confirmed: false` — uncertain; flag for audit.
`opted_out: true` — page exists for graph linkage only; leave content fields blank.
`aka` — nicknames and aliases; source of truth for alias resolution.

## Source pages

```yaml
---
title: 
tags: []
type: source
status: reference
workstream: 
raw_source: raw/processed-<slug>.md
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: 1
---
```

`raw_source` — relative path to processed markdown in `raw/`. For already-markdown sources, point to the original file. Enables traceability for hallucination verification.

## YAML value quoting

Wrap any value containing `: ` (colon-space) in double quotes — strict YAML parsers treat bare `: ` as a key separator.

```yaml
# Bad
title: Agent Skills – Best Practices: Checklist

# Good
title: "Agent Skills – Best Practices: Checklist"
```

## Relationships

Any frontmatter field whose value is a `[[wikilink]]` or list of `[[wikilinks]]` is a typed relationship. Field name = relationship type. No registration required.

```yaml
belongs_to:
  - "[[proget]]"
related_to:
  - "[[open-source-curation]]"
covers_game:
  - "[[concordia]]"
```

Common names: `belongs_to`, `related_to`, `has`, `covers`, `authored_by`. Add relationship fields whenever a meaningful typed link exists.

**Naming convention:** always snake_case. Singular for typed relationships to a single target: `authored_by`, `covers_game`. Plural when the field commonly holds multiple values: `related_to`, `belongs_to`. Never camelCase, never hyphenated. Note: ADR section headers (`Related:`, `Supersedes:`) are distinct from frontmatter field names and follow their own convention (see ADR-0009).

## Subdirectory index pages (`_index.md`)

Applies to `wiki/concepts/<topic>/` and `wiki/entities/<topic>/` subdirectories.

```yaml
---
title: "<Topic> Index"
type: index
---
```

Required body: a table with `Page` and `Description` columns, rows sorted alphabetically by page slug. `Description` = one-line summary matching the format of entries in `wiki/index.md`. No `sources` field.

```markdown
| Page | Description |
|------|-------------|
| [[page-a]] | One-line summary |
| [[page-b]] | One-line summary |
```

Upsert on every ingest that touches the subdir.
