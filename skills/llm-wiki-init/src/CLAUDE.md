# {{VAULT_NAME}}

You maintain the `wiki/` layer. You never write outside `wiki/`.

**Authorship rules:**
- LLM writes and maintains `wiki/` only
- Source files are human-dropped — read them, never modify them
- `capture.md` is shared — human appends entries, LLM strikes them through after processing

---

## Session Startup Protocol

Run at the start of every session, before anything else:

1. `rg "^## \[" wiki/log.md | tail -10` — recent activity
2. Read `wiki/index.md` — lightweight catalog of all pages
3. Scan `capture.md` for unprocessed entries (not yet struck through)
4. `rg "^## \[" wiki/log.md | rg " cleanup " | tail -1` — find last cleanup run. Report how long ago it was and ask the user if they'd like to run cleanup now.

This rebuilds working memory without re-reading the full wiki. Read individual pages only when a query specifically requires them.

---

## Vault Structure

```
vault/
  capture.md      ← shared inbox: human appends, LLM strikes through on ingest
  CLAUDE.md       ← this file (primary AI contract, Claude Code auto-loads)
  Start Here.md   ← human setup and day-to-day guide
{{SOURCE_STRUCTURE_BLOCK}}
  .claude/
    rules/        ← path-scoped rules (load JIT when matching files opened)
  wiki/
    entities/     ← proper nouns: people, places, orgs, named objects
    concepts/     ← ideas, themes, frameworks
    sources/      ← one LLM-written summary page per ingested source
    analysis/     ← cross-cutting analysis, comparisons, discovered connections
    index.md      ← content catalog (update on every ingest)
    log.md        ← append-only chronological record
    decisions/    ← ADR files (NNNN-slug.md) + index.md
```

---

## Operations

Skills for ongoing vault management are provided by the `llm-wiki-mgmt` plugin. Install it from the isaidhey marketplace after initialization.

| Operation | Trigger |
|-----------|---------|
| Ingest | New source arrives or capture.md has a ready entry |
| Query | User asks a question answerable from wiki content |
| Lint | Health check — run periodically or after bulk changes |
| Map | Structure discovery — run when wiki feels incoherent |
| Cleanup | Remove conversion noise from processed source files |

---

## Special Files

Never rename or merge these:

| File | Purpose | Update frequency |
|------|---------|-----------------|
| `wiki/index.md` | Content catalog — every page listed with link + summary | Every ingest |
| `wiki/log.md` | Append-only chronological record | Every operation |
| `wiki/decisions/` | ADR files + `index.md`. Use `isaidhey:decided` skill to create, supersede, or retire. | When decisions change |
| `capture.md` | Shared handoff inbox | On capture / review pass |

## ADR Directory

ADRs are stored in `wiki/decisions/`.

*Initialized {{CREATED_DATE}}*
