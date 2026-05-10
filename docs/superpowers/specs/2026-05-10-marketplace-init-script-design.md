# marketplace-init script delegation design

**Date:** 2026-05-10
**Status:** approved

## Summary

Refactor `marketplace-init` skill to delegate all prompting and file creation to a bash script. Skill becomes a thin orchestrator: call script, parse output, render next steps.

## Motivation

Current skill wizard lives entirely in SKILL.md. All steps are mechanical (no reasoning required). A bash script is more appropriate: independently runnable, faster, no Claude overhead for straightforward prompts.

## Components

### `skills/marketplace-init/scripts/init.sh`

Handles everything except next-steps display.

**Inputs:** named options (all optional — script prompts interactively for any not supplied):

| Flag | Value |
|------|-------|
| `--name` | marketplace name |
| `--dir` | target directory |
| `--owner-name` | owner/team name |
| `--owner-email` | owner email |
| `--description` | marketplace description |

Parsed via `while [[ $# -gt 0 ]]; do case "$1" in ...` pattern. Unknown flags → error + usage, exit 1.

**Prompt sequence:**

1. **Marketplace name**
   - Prompt: `Marketplace name:`
   - Validate: kebab-case (`^[a-z][a-z0-9-]*$`), not in reserved list
   - On fail: print error, re-prompt

2. **Directory** (numeric menu, no defaults)

   If `$name` directory exists:
   ```
   Directory options:
     1) Use ./$name
     2) Enter a different directory
     3) Cancel
   Enter your choice:
   ```

   If `$name` directory does not exist:
   ```
   Directory options:
     1) Create ./$name
     2) Enter a different directory
     3) Cancel
   Enter your choice:
   ```

   - Choice 1: `dir=$name` (mkdir if "Create" variant)
   - Choice 2: prompt `Directory path:` → if path doesn't exist → `Directory does not exist. Create it? [Y/n]` (default Y) → n → return to dir menu
   - Choice 3: exit 1
   - Invalid input: re-show menu

3. **Owner name** (required, re-prompt if blank)

4. **Owner email** (optional — blank = omit from JSON)

5. **Description** (required, re-prompt if blank)

**Pre-write check:**
- If `$dir/.claude-plugin/marketplace.json` already exists → print error to stderr, exit 1

**File creation:**
- `mkdir -p $dir/.claude-plugin/`
- Write `$dir/.claude-plugin/marketplace.json`

**stdout on success:** single JSON line
```json
{"dir":"<dir>","name":"<name>","path":"<dir>/.claude-plugin/marketplace.json"}
```

**Exit codes:** 0 = success, 1 = cancelled or error (error message to stderr).

### `skills/marketplace-init/SKILL.md`

Stripped to a shim:

1. Run `bash skills/marketplace-init/scripts/init.sh` forwarding `$name` and `$dir` as `--name` / `--dir` if supplied
2. On exit 1: surface stderr, stop
3. On exit 0: parse stdout JSON, render next-steps markdown with substituted values

**Next steps content** (unchanged from current skill):
- Validate: `claude plugin validate <path>`
- Add plugin: `claude plugin add <name> --marketplace <path>`
- Install: `claude plugin install <name>`
- Version management note

## Reserved names

Copied from current `docs/schema.md`:
`claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `knowledge-work-plugins`, `life-sciences`

## marketplace.json output shape

```json
{
  "$schema": "https://json.schemastore.org/claude-code-marketplace.json",
  "name": "<name>",
  "description": "<description>",
  "version": "1.0.0",
  "owner": {
    "name": "<owner-name>",
    "email": "<owner-email>"
  },
  "plugins": []
}
```

Email key omitted when user skips.

## Out of scope

- Non-interactive mode (all flags supplied → skip all prompts)
