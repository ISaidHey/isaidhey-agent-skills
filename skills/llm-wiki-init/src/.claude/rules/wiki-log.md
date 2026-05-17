---
paths:
  - "wiki/log.md"
---

# Wiki Log Rules

## No bare wikilinks in log entries

Log entries are prose. Wikilink syntax in log text must be backtick-wrapped when illustrative, not rendered as live links.

**Bad** (bare wikilink in log body):
```
## [2026-05-09] Ingested agent-skills docs
Created [[concepts/claude-code/skills-why]] and related pages.
```

**Good** (backtick-wrapped — illustrative, not navigational):
```
## [2026-05-09] Ingested agent-skills docs
Created `[[concepts/claude-code/skills-why]]` and related pages.
```

Exception: a wikilink that is genuinely navigational (pointing a reader to a page for follow-up) may be left bare. When in doubt, backtick-wrap.

Source: ADR-0005.
