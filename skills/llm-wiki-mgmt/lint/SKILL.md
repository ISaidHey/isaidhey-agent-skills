---
name: lint
description: Use when the user asks for a health check, audit, or lint; after bulk ingest; or when the wiki may have broken links, orphan pages, missing frontmatter, uncited claims, or index drift.
---

# Skill: Lint

Health check. Run across all wiki pages to find and fix structural issues.

---

Check for:

1. **Broken links** — `[[wikilinks]]` pointing to pages that don't exist
2. **Orphan pages** — pages with zero inbound links (excluding `index.md`, `log.md`, `decisions/index.md`)
3. **Missing frontmatter** — pages without YAML frontmatter block
4. **Empty pages** — pages with no body content after frontmatter
5. **Not in index** — wiki pages not listed in `wiki/index.md`
6. **Index entries pointing to missing files** — entries in `index.md` whose target file is gone
7. **Uncited claims** — entity, concept, or analysis pages with prose claims but no `[[sources/]]` links

## Decision checks (`wiki/decisions/`)

8. **Missing required frontmatter fields** — every decision file must have: `type`, `id`, `title`, `status`, `date`
9. **Invalid status** — `status` must be one of `proposed`, `rejected`, `active`, `superseded`, `retired`
10. **Superseded without wikilink** — if `status: superseded`, `superseded_by` must be a non-empty wikilink (`[[...]]`)
11. **Broken superseded_by** — `superseded_by` wikilink must resolve to an existing file in `wiki/decisions/`
12. **Decision not in decisions index** — every `NNNN-*.md` file in `wiki/decisions/` must appear in `wiki/decisions/index.md`
13. **Index entry pointing to missing decision** — entries in `wiki/decisions/index.md` whose target file is gone
14. **ID collision** — two decision files sharing the same `id` frontmatter value

For each issue: fix broken links by creating the missing page or updating the reference; connect orphans by adding wikilinks from related pages; add frontmatter to pages missing it. For decision issues, report and ask the user before modifying — don't auto-fix status or supersession fields.

## Entity and content checks

15. **Unconfirmed entities** — entity pages with `confirmed: false`. For each: run `rg '"<title_value>"' wiki/entities/` using the page's exact `title` value to find aka phrase matches in other entity files. Report with candidates:
    ```
    wiki/entities/john.md — unconfirmed entity "John"
      Candidate match: [[john-smith|John Smith]] (aka: "Johnny", "John S.")
      Action: confirm merge or set confirmed: true if distinct
    ```
    If no candidates found, report `no candidates — review manually`. Fresh lookup each lint run — no stale state stored on entity pages.

16. **Full-path wikilinks** — `[[wiki/concepts/…]]` or `[[wiki/entities/…]]` patterns that should use short-form `[[topic/page-name]]`. Run: `rg '\[\[wiki/(concepts|entities)/' wiki/`. Report each match as `file:line: use short-form [[topic/page]] instead of full path`.

17. **Bare wikilinks in log** — `[[wikilink]]` not wrapped in backticks within `wiki/log.md`. Run: `rg '\[\[' wiki/log.md | rg -v '\`\[\['` to find lines containing wikilinks not preceded by a backtick. Report each as `wiki/log.md:line: bare wikilink — backtick-wrap per ADR-0005`.

18. **Bare angle-bracket placeholders in bold/emphasis** — patterns like `**<foo>**` or `*<foo>*`. Run: `rg '\*+<[^>]+>\*+' wiki/ wiki/decisions/`. Report each as `file:line: bare <placeholder> in bold/emphasis — backtick-wrap per ADR-0005`.

Append to log: `## [YYYY-MM-DD] lint | N issues found — summary`
