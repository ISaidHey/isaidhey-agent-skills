---
paths:
  - "wiki/**/*.md"
---

# Topic Namespacing

When a topic domain accumulates enough pages, create a subdirectory rather than leaving all pages flat.

## Thresholds

| Domain type | Create subdir when… |
|-------------|---------------------|
| Named product / brand / game | 3+ concept pages |
| Generic topic | 4+ pages |

Named products get the lower threshold because they are bounded, self-referential domains — isolation is warranted sooner.

## Applying the rule

- Subdir: `wiki/concepts/<topic>/` or `wiki/entities/<topic>/`
- Keep filenames short inside the subdir
- Wikilinks use short form: `[[topic/page-name]]` — not full paths

## Invariants

- Do not apply the 4+ generic threshold to named products/brands/games
- Do not flatten existing topic subdirs back to parent once established
- Always use `[[topic/page-name]]` short form — never full path wikilinks
