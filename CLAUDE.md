# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repo.

## What This Repo Is

Claude Code plugin skill repo. Hosts `marketplace-init` skill — Bash interactive scaffold generator for Claude Code plugin marketplaces.

## Development Commands

No build system. No package manager. Skills run directly.

**Test the script manually:**
```bash
bash skills/marketplace-init/scripts/init.sh --help
bash skills/marketplace-init/scripts/init.sh --name my-marketplace --dir /tmp/test-market --owner-name "Test User" --owner-email test@example.com --description "test"
```

**Check runtime deps before running:**
```bash
command -v jq && jq --version
realpath --version 2>/dev/null || echo "GNU realpath missing"
```

## Architecture

Two-file execution model:

1. **`skills/marketplace-init/SKILL.md`** — Skill manifest. Claude Code runtime reads this; defines invocation, prompts, calls `init.sh`, parses stdout JSON.
2. **`skills/marketplace-init/scripts/init.sh`** — Worker script. Validation, interactive prompts, file creation, emits single JSON line to stdout.

Data flow: `User invokes /marketplace-init` → SKILL.md parses args → `init.sh` runs → stdout JSON → SKILL.md renders result.

**`init.sh` flow (line ranges):**
- `:1-60` — dep checks, option parsing, `--help`
- `:62-81` — name validation (regex + reserved list)
- `:83-127` — interactive directory selection menu
- `:129-147` — owner name/email/description prompts
- `:149-157` — path canonicalization + pre-write safety check
- `:159-192` — create dir, write `marketplace.json` via `jq`
- `:194-196` — emit JSON result to stdout

## Critical Constraints (from ADR 0001)

- All user-supplied values pass through `jq --arg`, never string-interpolated — prevents JSON injection
- Name regex: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$` — rejects trailing/double hyphens
- Path canonicalization via `realpath --canonicalize-missing` — prevents traversal
- Reserved names enforced in `init.sh`, not server-side

## Reference Docs

- `skills/marketplace-init/docs/schema.md` — `marketplace.json` field reference
- `skills/marketplace-init/docs/validation.md` — validation rules & testing
- `skills/marketplace-init/docs/distribution.md` — hosting & team distribution
- `docs/decisions/0001-marketplace-init-skill.md` — ADR: design rationale
