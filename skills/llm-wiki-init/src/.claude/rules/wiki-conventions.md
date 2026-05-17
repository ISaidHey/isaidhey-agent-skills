---
paths:
  - "wiki/**/*.md"
---

# Wiki Conventions

## Formatting

- **Filenames:** kebab-case — `my-topic-name.md`
- **Wikilinks:** `[[page-name]]` to link; `[[page-name|Display Text]]` for custom display
- All cross-references inside wiki pages use `[[wikilinks]]` — never plain markdown links
- **Callouts:** `> [!NOTE]` · `> [!WARNING]` · `> [!TIP]`
- One topic per file. Split large topics into sub-topics.
- Prefer concrete examples over abstract descriptions.

## Voice and attribution

All wiki content uses **third person with attribution**:
- ✓ `[[alice-smith|Alice Smith]] proposed expanding the pilot[^q2-retro]`
- ✗ `I proposed expanding the pilot`

Anonymous sources are fine — ingest without attribution if no author is clear.

**Multi-author attribution:**
- **1–3 authors:** link all with `[[wikilink]]` at every mention
- **4+ authors:** create a collective entity page (e.g., `[[vaswani-et-al-2017]]`); link all individuals on that entity page
- "Primary author only" is not an option — partial attribution creates orphaned entities

## Entity wikilinks

Every person mentioned gets:
1. An entity page at `wiki/entities/<kebab-full-name>.md`
2. A `[[kebab-full-name|Full Name]]` wikilink at **every mention**

The name is the wikilink — not a trailing citation:
- ✓ `[[alice-smith|Alice Smith]] proposed it[^source]`
- ✗ `Alice Smith proposed it [[wiki/entities/alice-smith]]`

**Name matching — exact full-name only:**
- `Jane Smith` → `[[jane-smith|Jane Smith]]` ✓
- `Jane` → link only if `wiki/entities/jane.md` exists
- Ambiguous during attended ingest: ask. During unattended: `confirmed: false`, flag.

**Aka resolution:** use `rg` on `wiki/entities/` to find matching `aka` values. Link to canonical slug — never to an alias slug. New aliases found on ingest → add to entity's `aka` field.

**Opt-out:** create entity page with `opted_out: true`, leave content blank. Page exists for graph linkage only.

## Citations

Every factual claim uses footnote-style citation. Source slug is the footnote key.

```markdown
The mechanism was first described in 2017[^attention-is-all-you-need].

[^attention-is-all-you-need]: [[sources/attention-is-all-you-need#p7]]
```

Span anchors in the footnote definition, not inline:

| Anchor | Use for |
|--------|---------|
| `#p7` | page number |
| `#para3` | paragraph number |
| `#1820` | timestamp (mm:ss) |
| `#s2` | section number |
| `#fig3` | figure number |
| `#t2` | table number |
| `#fn5` | footnote number in source |

Do not invent anchor types outside this list. If no anchor fits, use the nearest page number (`#p7`).

A `[[sources/]]` link to a file not yet ingested is a confabulation signal — treat as lint error. If a claim can't be cited, mark `> [!NOTE] Uncited — needs source` or omit it.

## Angle brackets in bold spans

Wrap `<placeholder>` text in backticks inside bold/emphasis spans — see ADR-0005 for rationale and examples.
