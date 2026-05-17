---
type: decision
id: "0004"
title: "Content format conventions"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
Wiki pages need three interdependent format choices: markup format, citation format, and relationship structure. These are evaluated together because each constrains the others. A central registry of allowed relationship field names would require schema approval for every new type, adding friction without benefit.

## Decision
**All LLM-written pages use Obsidian-flavored markdown with `[[wikilinks]]`, YAML frontmatter, and callouts. Every page gets a `status` frontmatter field. Obsidian Bases is the query layer — no Dataview.**

**Citations use `[^slug]` footnote syntax inline, with `[^slug]: [[sources/slug#anchor]]` defined once at page bottom.** Multiple claims may reuse the same key. The canonical anchor type table (all valid types, no-invent rule) is in wiki-conventions.md. Every factual claim must be cited.

**Any frontmatter field whose value is a `[[wikilink]]` or list of `[[wikilinks]]` is treated as a typed relationship.** The field name becomes the relationship type label. No registration or schema update required.

Details:
- `[[wikilinks]]` for all cross-references; plain markdown links are not used inside wiki pages
- Callouts (`> [!NOTE]`, `> [!WARNING]`, `> [!TIP]`) for flagging contradictions and caveats
- `status:` field drives Bases views equivalent to PARA (active / reference / archived)
- Bases is first-party Obsidian — no extra plugin dependency; queries frontmatter directly

## Consequences
Graph view, backlinks, and Bases work natively. Prose is readable with citations structurally enforced at page bottom. New relationship types can be added inline without coordination overhead. **Re-evaluate if:** vault migrates away from Obsidian, Bases proves insufficient, or relationship field proliferation creates inconsistency that needs governance.

## Invariants
- Do not switch to plain markdown links inside wiki pages
- Do not create PARA subdirs inside `wiki/` — use `status` frontmatter instead
- Do not install Dataview
- Do not use inline wikilink citations in prose; footnote definitions belong at page bottom
- Citation is mandatory for every factual claim
- Do not create a hardcoded list of allowed relationship field names
- Do not require schema approval to use a new relationship field
