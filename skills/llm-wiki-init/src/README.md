# llm-wiki

A knowledge base that builds itself. You drop sources; Claude maintains the wiki.

## What it is

A two-layer system:

- **You** drop source files and queue them in `capture.md`
- **Claude** reads them, extracts knowledge, and maintains `wiki/` — entities, concepts, cross-references, citations

The wiki grows over time. You never do the bookkeeping.

## Stack

- [Obsidian](https://obsidian.md) — vault UI, graph view, wikilinks (free)
- [Claude Code](https://claude.ai/code) — the agent that runs in this directory
- `markitdown` — converts PDFs/Office docs to markdown for ingestion (`pip install 'markitdown[all]'`)
- `defuddle` — strips nav/ads from web pages before ingestion (`npx defuddle <url>`)

## Getting started

1. Use this template to create your own repo
2. Clone your repo
3. Open [Claude Code](https://claude.ai/code) in the repo directory: `claude`
4. Claude will walk you through setup (~5 minutes)

## What setup does

- Explains how the system works
- Asks how you want to organize your source files
- Names your vault
- Scaffolds the directory structure and configuration

After setup, see `Start Here.md` for day-to-day usage.

## Suggested plugins

These aren't required but work well alongside llm-wiki:

| Plugin | What it adds |
|--------|-------------|
| [`isaidhey:decided`](https://github.com/ISaidHey/isaidhey-agent-skills) | Record architectural decisions as ADRs in `wiki/decisions/` |

Install via Claude Code:
```bash
claude plugin marketplace add isaidhey-agent-skills https://github.com/ISaidHey/isaidhey-agent-skills
claude plugin install isaidhey@isaidhey-agent-skills
```
