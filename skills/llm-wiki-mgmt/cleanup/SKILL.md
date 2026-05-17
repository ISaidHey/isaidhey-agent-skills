---
name: cleanup
description: Use when processed markdown files have conversion noise (OCR artifacts, garbled text, InDesign metadata, layout junk), the user approves cleanup at session start, or explicitly requests it.
---

## Source file location

{{SOURCE_PATH_DESCRIPTION}}

---

# Skill: Cleanup

Remove conversion noise from processed markdown files in `raw/processed-*.md`. Run on-demand — not part of the ingest flow. Startup protocol checks when this last ran and prompts the user.

---

## When to run

Manually, when the user approves at session startup or explicitly requests it. Typically run across all `raw/processed-*.md` files that have been added since the last cleanup log entry.

---

## Procedure

1. **Read the original source** — use the Read tool on the original source file (path per source structure above) to build a ground-truth understanding of the document's structure and content.
2. **Read the processed file** — read `raw/processed-<slug>.md` in full.
3. **Identify and remove noise.** Common artifact types:

   | Artifact | Pattern | Action |
   |----------|---------|--------|
   | **Print/InDesign metadata** | `Filename.indd   N` / `MM/DD/YY  H:MM PM` | Remove |
   | **Copyright watermarks on illustrations** | Repeated fragmented strings like `H b m G n a t a C 5 1 0 2 ©` or similar short character runs interspersed throughout | Remove |
   | **Garbled illustration text** | Nonsense strings that don't form readable sentences and appear adjacent to `Illustration X` labels | Remove; keep the `Illustration X` label if it serves as a reference anchor |
   | **Layout-as-text** | Strings of numbers and symbols representing spatial diagrams or UI layouts | Remove unless the numbers carry standalone meaning (e.g., a component list) |
   | **Orphaned page numbers** | A bare integer on its own line between content paragraphs | Remove |
   | **Single-letter section markers** | A lone letter (`A`, `B`, `C`) on its own line used as illustration callout labels | Remove |

4. **Preserve everything else**, including:
   - All prose rules, definitions, and instructions
   - Headings and section titles (even if oddly cased)
   - Bullet lists and structured data
   - Domain-specific terminology, defined terms, and named items
   - Example blocks and illustrative content
   - Numeric data in structured contexts (tables, lists, sequences) — not layout artifacts

5. **Write the cleaned content** back to `raw/processed-<slug>.md`, overwriting the noisy version.

6. **Do not modify** the original source file (path per source structure above) — it is immutable.

7. **Log the run.** After all files are cleaned, append to `wiki/log.md`:
   ```
   ## [YYYY-MM-DD] cleanup | processed-<slug>.md (and any others cleaned this run)
   ```
   The ` cleanup ` token (with surrounding spaces) is the search key used by the startup protocol to find this entry.

---

## Quality check

After writing, do a spot check: pick 3–5 factual claims from the original source and verify they are still present and accurate in the cleaned file. If any claim is missing, restore it before proceeding to ingest.

---

## Notes

- When in doubt about a fragment: if it cannot be matched to any passage in the original source, remove it.
- If the entire processed file is too noisy to clean reliably (e.g., scanned image-only PDF with no real text layer), flag it with `> [!WARNING] Processed file unreliable — source is image-based; verify all claims against original` at the top of the file rather than attempting cleanup.
