---
name: map
description: Use when the wiki has grown by multiple pages since the last map run, when recurring concepts lack dedicated pages, when pages discuss the same topic without linking each other, or when the user asks to map, explore structure, or find patterns.
---

# Skill: Map

Latent structure discovery. Run when the wiki has grown significantly or feels incoherent. Less frequent than Lint.

---

## Procedure

1. **Scan for recurring concepts** — `rg -h "^- \[\[" wiki/concepts/ wiki/entities/ | sort | uniq -c | sort -rn` to find frequently cross-referenced topics. Any concept appearing in 3+ pages but lacking its own page is a candidate.
2. **Scan for implicit connections** — read through `wiki/index.md`; identify pages covering overlapping topics that have no `[[wikilink]]` between them.
3. **Identify emerging clusters** — look for groups of pages that share a domain but have no parent category or subdirectory.
4. **Confirm before creating** — present findings to user before writing any new pages. Describe: what page(s) would be created, what existing pages would gain cross-refs.
5. **Create new pages** — use **ingest** skill for each approved new concept page or cross-reference addition.
6. **Add cross-references** — add `[[wikilinks]]` between existing pages that are implicitly connected.
7. **Append to log** — `## [YYYY-MM-DD] map | Summary of findings`

## Common Mistakes

- Creating concept pages without first checking if the concept already exists under a different name (`rg "^title:" wiki/concepts/` to scan)
- Writing new pages during map without confirming with the user — map is discovery, not autonomous ingest
- Running map too frequently — it's a structural review, not a per-session task
