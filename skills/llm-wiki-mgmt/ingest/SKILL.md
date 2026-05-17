---
name: ingest
description: Use when a new source file arrives, when capture.md has a ready entry, or when the user says to ingest, add, or process a source.
---

## Source file location

{{SOURCE_PATH_DESCRIPTION}}

---

# Skill: Ingest

Process a new source into the wiki. A single source typically touches 10–15 wiki pages.

---

0. **Attended vs unattended.** Determine mode per ADR-0006. Default: attended. Governs: (a) ambiguous name matches in step 5, (b) entity creation under uncertainty.

1. **Pre-process if needed (distinct step — do this before anything else).** For plain text/markdown: skip this step. For PDFs, Word docs, PowerPoints, Excel files: convert to markdown and save to `raw/processed-<slug>.md` — e.g., `markitdown raw/file.pdf > raw/processed-file.md`. Never reconvert; if `raw/processed-<slug>.md` already exists, skip conversion and read it directly.
2. **Read the source once.** For plain text/markdown: read the source file directly (path per source structure above). For pre-processed files: read `raw/processed-<slug>.md`. Do not re-read or reconvert after this step.
3. Discuss key takeaways if the user is present
4. **Attribution:** identify the author(s) if present in the source or `capture.md` entry. Convert any first-person voice to third person with attribution. If author is unknown, proceed without attribution. Multi-author attribution per wiki-conventions.md.
5. **Name resolution:** identify all people mentioned. Apply 4-rung resolution ladder per ADR-0006. Commands:
   - Title check: `rg "^title: \"Full Name\"" wiki/entities/`
   - Aka check (full names ≥2 words only): `rg '"Full Name"' wiki/entities/`
   - Single-word names: skip — treat as no-match
6. **Plan page structure before writing.** Count how many pages the source will generate:
   - If pages under a single topic domain reach the namespacing threshold — **3+ pages** for a named product, brand, or game; **4+ pages** for a generic topic — create a subdirectory: `wiki/concepts/<topic>/`, `wiki/entities/<topic>/`, etc. Use short filenames inside the folder — the folder provides namespace context. Wikilinks use the slug form: `[[topic/page-name]]`. Per wiki-namespacing.md.
   - If fewer than 4 pages, place files flat under the parent directory as normal.
   - If the folder decision sets a precedent, record it using the `isaidhey:decided` skill.
6b. **Thin section handling.** Identify and handle thin sections per ADR-0010.
7. Create `wiki/sources/<slug>.md` — full summary with frontmatter. Set `sources: 1`. Include `raw_source` field: set to `raw/processed-<slug>.md` for pre-processed files, or the source file path for sources that were already markdown. **Sources field rule (steps 7–11):** on create set `sources: 1`; on update increment `sources` by 1. Per wiki-schema.md. Rule applies to all page types in steps 8–11 — not restated there.
8. Create or update entity pages in `wiki/entities/` for all people mentioned — wikilink every mention; every claim cites `[[sources/<slug>]]`; populate `aka` field for any aliases/nicknames found.
9. **Entities are proper nouns — person, place, or thing.** Create or update entity pages for any named noun: places, organizations, named objects, named game pieces, named locations, named non-human entities, or any noun consistently referred to by a specific proper name. Every claim cites `[[sources/<slug>]]`; populate `aka` if applicable.
10. Create or update concept pages for themes, mechanics, and ideas — every claim cites `[[sources/<slug>]]`.
11. **Analysis check.** Create or update `wiki/analysis/` pages per ADR-0011. Every claim cites `[[sources/<slug>]]`.
12. Update `wiki/index.md` — upsert entries for all new or updated pages
12b. **`_index.md` maintenance.** If the ingest touches a subdirectory under `wiki/concepts/` or `wiki/entities/`, upsert that subdir's `_index.md` per wiki-schema.md spec. Also run standard step 12 for global `wiki/index.md`.
13. Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | Source Title` — wrap any `[[wikilink]]` syntax in backticks to prevent Obsidian stub creation
14. Strike through the `capture.md` entry for this source
15. Add `[[wikilinks]]` from new pages to related existing pages and back

## Common Mistakes

- Reconverting an already-processed file — if `raw/processed-<slug>.md` exists, read it directly; never re-run `markitdown`
- Skipping name resolution (step 5) for people mentioned casually — all people get the 4-rung ladder regardless of mention frequency
- Setting `sources: 1` on an update — create = `sources: 1`; update = increment by 1; check existing value first
- Applying the wrong subdirectory threshold in step 6 — named products/brands/games: 3+ concept pages; generic topics: 4+ pages (per ADR-0007). Don't apply the 4+ generic threshold to named products
- Forgetting to update `wiki/index.md` (step 12) after creating new pages
- Creating entity pages for common nouns — entities are proper nouns only (person, place, named thing)
