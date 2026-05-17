---
paths:
  - "wiki/index.md"
---

# Wiki Index Format

`wiki/index.md` uses list entries under section headers. Each entry: `- [[path]] — one-line summary`.

```markdown
# Index

## Sources

- [[sources/example]] — one-line summary

## Entities

- [[entities/name]] — one-line summary

## Concepts

- [[concepts/name]] — one-line summary

## Analysis

- [[analysis/name]] — one-line summary
```

Upsert on every ingest: remove any existing entry for the page, insert under the correct section. Never duplicate entries.

Do not revert to table format. Source: ADR-0006.
