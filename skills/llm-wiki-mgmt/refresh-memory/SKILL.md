---
name: refresh-memory
description: Use when switching topics mid-session, after startup, or when the user asks to refresh, reload, or read wiki pages into context.
---

# Skill: Refresh Memory

Deep-read specific wiki pages into context. Use when a query requires more than the index summary — after startup, mid-session, or when switching topics.

---

## Arguments

| Invocation | Behavior |
|---|---|
| `/refresh-memory` | Read all pages from the most recent log entry |
| `/refresh-memory <topic>` | Read all pages under `concepts/<topic>/` and `entities/<topic>/` |
| `/refresh-memory <YYYY-MM-DD>` | Read all pages from log entries on that date |

---

## Procedure

1. **Determine scope from argument:**

   - **No argument:** `rg "^## \[" wiki/log.md | tail -1` — get the last log entry. Extract every page path mentioned (expand any brace-notation like `concepts/catan/{rules,trading}` into individual paths).
   - **Topic arg:** `ls wiki/concepts/<topic>/ wiki/entities/<topic>/` — collect all `.md` files.
   - **Date arg:** `rg "^## \[<date>\]" wiki/log.md` — extract all entries for that date; collect page paths from each.

2. **Cap check:** if scope resolves to more than 8 pages, list them and ask the user which to prioritize before reading. Do not silently read 20+ pages.

3. **Read each page** in the resolved scope.

4. **Report:** one-line summary per page read. Flag any pages that were missing or couldn't be resolved.

## Common Mistakes

- Reading 8+ pages silently — always ask which to prioritize when scope exceeds the cap
- Confusing with `/query` — this skill loads raw context; use `/query` to answer a question from that context
- Passing a topic that doesn't match any `wiki/concepts/<topic>/` or `wiki/entities/<topic>/` directory — `ls` will return nothing; report the miss rather than reading unrelated pages
- Using `/refresh-memory` as a substitute for startup — it supplements context mid-session, not replaces the initial index read
