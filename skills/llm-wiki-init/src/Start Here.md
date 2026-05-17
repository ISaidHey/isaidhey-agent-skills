# Start Here

## Prerequisites

- **[Obsidian](https://obsidian.md)** — open this vault (free)
- **[Claude Code](https://claude.ai/code)** — `npm install -g @anthropic-ai/claude-code`
- **Optional:** `pip install 'markitdown[all]'` — converts PDFs and Office docs to markdown
- **Optional:** `npx defuddle <url>` — strips nav/ads from web pages before ingestion

---

This vault has two layers. You drop things in [SOURCE_DIR_DESCRIPTION] and `capture.md`. Claude builds and maintains `wiki/`.

The wiki is a growing, interlinked knowledge base. You add sources — articles, documents, transcripts, PDFs. Claude reads them, extracts what matters, and weaves the knowledge into the wiki. Cross-references, summaries, and connections accumulate over time. You never do the bookkeeping.

---

## The structure

```
vault/
  capture.md    ← quick capture and ingestion queue
  [SOURCE_TREE] ← source files: PDFs, docs, exports, transcripts
  wiki/         ← Claude's knowledge base (don't edit by hand)
  CLAUDE.md     ← instructions for Claude
```

---

## Day to day

**Drop a source file:** put it in [SOURCE_DIR]. Then add a line to `capture.md`:
```
- [YYYY-MM-DD] Article title — https://example.com
- [YYYY-MM-DD] Q2 strategy deck — [SOURCE_DIR]/q2-strategy.pdf
```

**Start a Claude session:**
```bash
claude
```
Claude reads the recent log and wiki index, then asks what you want to do.

**Ask a question:** just ask. Claude searches the wiki and synthesizes a cited answer.

---

## The four operations

**Capture** — append to `capture.md`. No processing required.

**Ingest** — Claude reads a source, extracts key information, and updates the wiki. One source typically touches 10–15 pages. Strikes through the `capture.md` entry when done.

**Query** — you ask, Claude answers from the wiki with citations. Valuable answers get filed as new wiki pages.

**Lint / Map** — periodic health checks. Claude finds broken links, orphaned pages, and missing connections.

---

## Files that matter

| File | What it is |
|------|-----------|
| `capture.md` | Your inbox — append things here for Claude to process |
| `[SOURCE_DIR]` | Source files — drop PDFs, docs, exports here before ingestion |
| `CLAUDE.md` | Instructions for Claude |
| `wiki/index.md` | Catalog of every wiki page |
| `wiki/log.md` | History of every ingest, query, and maintenance pass |
| `wiki/decisions/` | Why things are set up the way they are (12+ ADRs) |
