---
type: decision
id: "0005"
title: "Content voice and wikilink rules"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
Wiki content often originates from first-person source material. In a shared wiki, "I" is ambiguous to readers. Attribution makes claims traceable; requiring it for every drop would create process friction for anonymous contributors.

Log entries in `wiki/log.md` use `[[wikilink]]` syntax illustratively, not navigationally. Linked-note tooling resolves bare wikilink syntax anywhere in the vault and creates stub files for unresolved ones — illustrative log entries would pollute the file tree.

## Decision
**All wiki content uses third-person with attribution. First-person voice in source material is converted on ingest. Anonymous drops are allowed — attribution can be suggested in `capture.md` but is never required.**

**Any `[[wikilink]]` syntax in `wiki/log.md` entries must be wrapped in backticks.** The full rule including the navigational exception (bare wikilinks that genuinely point a reader to a page for follow-up) is in wiki-log.md.

**Angle brackets in bold/emphasis spans:** linked-note renderers (Obsidian) parse bare `<placeholder>` inside `**bold**` or `*emphasis*` spans as HTML tags, silently dropping the enclosed text. Wrap all placeholder text in backtick code spans inside bold/emphasis: `` **Save to `raw/processed-<slug>.md`.** `` not `**Save to raw/processed-<slug>.md.**`. Placeholders outside bold/emphasis text are fine as-is.

## Consequences
Claims are attributable and traceable. Anonymous contributions flow without overhead. Log entries don't pollute the file tree with unwanted stub files. **Re-evaluate if:** use case shifts to single-author personal wiki where attribution is implicit, or log format changes and illustrative wikilinks are no longer needed.

## Invariants
- Do not allow first-person voice in wiki pages
- Do not block ingestion on missing attribution
- Do not write bare `[[wikilinks]]` in log entries — backtick-wrap all illustrative wikilink syntax
- Do not write bare `<placeholder>` text inside bold or emphasis spans — backtick-wrap all placeholder text
