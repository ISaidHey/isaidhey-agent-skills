---
paths:
  - "raw/**/*"
---

# Source Preprocessing

Convert non-markdown sources to markdown before ingesting. Save output to `raw/` with a `processed-` prefix. Ingest reads the processed file — never the original binary.

## PDFs, Word, PowerPoint, Excel

```bash
markitdown raw/file.pdf > raw/processed-file.md
```

For files with embedded images/diagrams:

```python
from markitdown import MarkItDown
from anthropic import Anthropic

md = MarkItDown(llm_client=Anthropic(), llm_model="claude-sonnet-4-6")
result = md.convert("raw/file.pptx")
# write result.text_content to raw/processed-file.md
```

## Web sources

Use defuddle to strip nav/ads. Always use `--md` for full verbatim markdown (preserves code examples, response schemas):

```bash
defuddle parse <url> --md
```

Do **not** append `.md` to the URL — defuddle requires HTML, not raw markdown.

Do **not** use WebFetch for ingestion — it summarizes and loses detail.

## Already-markdown sources

Place the file in `raw/` as-is. No conversion needed.

`raw_source` points to the original file — no `processed-` prefix:
```
raw_source: raw/<original-filename>.md
```

## Invariants

- `raw/` is read-only to Claude — never write, move, or delete files inside `raw/`
- Never ingest binary files directly
- Never delete processed markdown after ingest — it is the verbatim source for citation traceability
- `raw_source` on source pages must point inside `raw/`: `raw/processed-<slug>.md` for converted sources, `raw/<original>.md` for already-markdown sources
