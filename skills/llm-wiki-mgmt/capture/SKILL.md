---
name: capture
description: Use when user asks to review, process, or check the inbox; when capture.md has unprocessed entries; or at session start with pending entries found.
---

# Skill: Capture

Inbox management. Review `capture.md` for entries ready to promote to the wiki.

---

`capture.md` is the handoff inbox. Human appends entries; never edit existing ones. Format:
```
- [YYYY-MM-DD] description — optional URL or path to raw/
```

On a review pass:
1. Read `capture.md` top to bottom
2. For each unprocessed entry (not struck through): determine if it is ready to ingest
3. If ready — before ingesting, assess scope:
   - Does the entry describe a multi-page breakdown (e.g., "break down by X, Y, Z", a full rulebook, a large document)?
   - If yes: this is a **folder-level ingest** — plan the subdirectory structure and confirm with the user before writing any pages (see ingest skill step 5)
   - If no: proceed normally
4. **REQUIRED:** Use `ingest` skill
5. If not ready — leave it; optionally add a `> [!NOTE]` below explaining what's missing
6. After processing, strike through the entry:
```
- ~~[YYYY-MM-DD] description — handled~~
```

## Common Mistakes

- Entry has no URL and no path to `raw/` → not ready; leave it with a note explaining what's missing
- Modifying entry content — never change what the human wrote; only add strikethrough markup after processing
