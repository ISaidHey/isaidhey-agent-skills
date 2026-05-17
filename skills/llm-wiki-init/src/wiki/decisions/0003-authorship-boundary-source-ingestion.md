---
type: decision
id: "0003"
title: "Authorship boundary and source ingestion"
status: active
date: 2026-05-13
superseded_by: ""
---

## Context
Without a clear authorship boundary, an LLM agent could modify source files or write outside `wiki/`, destroying the audit trail. Tracing a wiki claim back to its source requires a reliable one-hop chain: wiki page → source summary → verbatim source text.

Binary sources (PDF, docx, pptx, xlsx) cannot be read by LLMs directly. Web sources fetched via `WebFetch` pass through a summarizing model before the LLM sees them, losing detail that citation traceability requires. Both need preprocessing that produces verbatim markdown.

## Decision
**LLM writes and maintains `wiki/` only. `raw/` is read-only to the LLM. Raw source files are never moved or deleted after ingestion. Every source page carries a `raw_source` frontmatter field pointing to the verbatim file in `raw/`.**

**Binary sources:** convert with `markitdown`, save to `raw/processed-<slug>.md`. For sources with embedded images or diagrams, pass an Anthropic client for inline descriptions. The original binary stays in `raw/` as-is.

**Web sources:** fetch with `defuddle parse <url> --md`. The `--md` flag is required for full verbatim markdown output. Do not append `.md` to the URL.

**Already-markdown sources:** place in `raw/` as-is. No conversion needed. `raw_source` points to the original file directly — no `processed-` prefix.

**`WebFetch` is excluded from ingestion** — it passes content through a summarizing model, breaking verbatim traceability.

The audit chain: wiki page claim → `[[sources/slug]]` citation → `raw_source` (either `raw/processed-<slug>.md` for converted sources, or `raw/<original>.md` for already-markdown sources) → exact text.

## Consequences
Source files stay under human control permanently. Any wiki claim is traceable to verbatim source in one hop. `raw/` grows over time but provides a complete, unbroken audit trail. Processed files are auditable and reusable without re-conversion. **Re-evaluate if:** a workflow emerges requiring LLM-managed source files with a different audit mechanism, or `raw/` grows to an unmanageable size.

## Invariants
- LLM must never modify files in `raw/`; LLM writes only to `wiki/` (and strikes through `capture.md`)
- Raw source files are never deleted or moved post-ingest
- Source pages must always carry `raw_source` pointing inside `raw/`
- Do not substitute `WebFetch` for `defuddle` during ingestion
- Do not omit the `--md` flag for `defuddle`
- Do not discard processed markdown after ingest — it is the verbatim source for citation traceability
