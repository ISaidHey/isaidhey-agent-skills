# plugin-init skill — design spec

**Date:** 2026-05-10  
**Status:** approved  
**Branch:** feat/marketplace-skill

---

## Overview

`plugin-init` scaffolds a new Claude Code plugin directory. Optionally creates a starter skill placeholder and registers the plugin in a local marketplace. Lives at `skills/plugin-init/` alongside the existing `marketplace-init` skill.

---

## File structure

```
skills/plugin-init/
├── SKILL.md
└── scripts/
    └── init.sh
```

Same two-file model as `marketplace-init`: SKILL.md drives the conversation, `init.sh` does file I/O.

---

## Script architecture

### Flags

```
--name NAME              Plugin name (kebab-case, required)
--dir DIR                Target directory (required)
--description DESC       Plugin description (required)
--author-name NAME       Author name (optional)
--author-email EMAIL     Author email (optional)
--skill-name NAME        First skill name (optional, triggers create_skill)
--skill-description D    First skill description (optional)
--register               Enable marketplace registration flow
--marketplace-dir DIR    Marketplace root (required when --register)
--marketplace-source S   Override default relative source path (optional)
--no-create              Skip plugin creation (register-only mode)
```

### Functions

| Function | Triggered by |
|---|---|
| `create_plugin` | default (unless `--no-create`) |
| `create_skill` | `--skill-name` present |
| `register_plugin` | `--register` |

Functions are isolated so the script can be split into separate scripts in the future without restructuring.

### stdout

Single JSON line on success:

```json
{
  "dir": "/abs/path/to/plugin",
  "name": "my-plugin",
  "plugin_json": "/abs/path/to/.claude-plugin/plugin.json",
  "skill_created": "my-skill",
  "registered": true,
  "marketplace_name": "my-marketplace",
  "marketplace_dir": "/abs/path/to/marketplace"
}
```

`skill_created` is `null` if no skill was created. `registered` is `false` and marketplace fields are `null` if `--register` was not passed.

---

## Function details

### `create_plugin`

1. Validate `--name` against `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`
2. `realpath --canonicalize-missing` on `--dir`
3. Abort if `.claude-plugin/plugin.json` already exists
4. `mkdir -p "$DIR/.claude-plugin"`
5. Write `plugin.json` via `jq --arg` (no string interpolation)

`plugin.json` output:

```json
{
  "name": "<name>",
  "description": "<description>",
  "version": "1.0.0",
  "author": { "name": "<author-name>", "email": "<author-email>" }
}
```

`author` omitted if neither name nor email supplied. `author.email` omitted if only name supplied.

### `create_skill`

> **Note:** This creates a minimal placeholder SKILL.md only. For fully-authored skills, use a dedicated skill-creation skill (e.g. `superpowers:writing-skills`) after the plugin scaffold is in place.

1. Validate `--skill-name` against same regex as plugin name
2. `mkdir -p "$DIR/skills/$SKILL_NAME"`
3. Write `skills/$SKILL_NAME/SKILL.md` with frontmatter from args:

```markdown
---
name: <skill-name>
description: <skill-description>
disable-model-invocation: true
---

# <skill-name>

TODO: Add skill instructions here.
```

`description` defaults to `"<skill-name> skill"` if `--skill-description` not supplied.

### `register_plugin`

1. Verify `$MARKETPLACE_DIR/.claude-plugin/marketplace.json` exists
2. Check plugin name not already present in `plugins[]` (abort if duplicate)
3. Compute relative source: `realpath --relative-to="$MARKETPLACE_DIR" "$DIR"`, prepend `./`
4. If `--marketplace-source` supplied, use that instead
5. Append plugin entry via `jq`:

```json
{
  "name": "<plugin-name>",
  "source": "./<relative-path>",
  "description": "<plugin-description>"
}
```

6. Read `marketplace.name` from JSON for result output

---

## SKILL.md conversation flow

```
User: /plugin-init [args]

Step 1 — Collect missing plugin fields
  Missing from args? Ask all in one message:
  name, dir, description, author-name, author-email (optional)

Step 2 — Run: init.sh [plugin-creation-args]
  (no flag needed — create_plugin runs by default)
  On non-zero exit: show stderr, ask troubleshoot or cancel
  On success: "✓ Plugin created at <path>"

Step 3 — First skill
  Ask: "Add a first skill? Provide name + description, or Enter to skip."
  If provided: run init.sh --no-create --skill-name ... --skill-description ...
  Note: this is a placeholder scaffold only. Use writing-skills skill for
        full skill authoring after scaffolding is complete.

Step 4 — Marketplace registration
  Ask: "Register in a marketplace? (y/N)"
  If yes:
    Inject marketplace discovery via shell:
      !`find . -maxdepth 4 -name "marketplace.json" -path "*/.claude-plugin/*" 2>/dev/null`
      (maxdepth 4 = up to 2 nesting levels for marketplace root + .claude-plugin/marketplace.json suffix)
    Present results:
      0 found → ask user to enter marketplace path
      1 found → confirm it
      2+ found → numbered list, user picks
    Confirm default relative source path, offer override
    Run: init.sh --no-create --register --marketplace-dir <dir> [--marketplace-source <s>]

Step 5 — Validation
  Run: claude plugin validate <plugin-dir>
  On pass: show output + next steps block
  On fail: show full output, offer troubleshoot or cancel
  If `claude` CLI absent: skip with note "install claude CLI to validate"
```

### Next steps block (success)

```
✓ Plugin created at <path>
✓ Skill placeholder created: <skill-name>    (if applicable)
✓ Registered in <marketplace-name>           (if applicable)

Validation passed.

Next steps:
1. Test locally:   claude --plugin-dir <plugin-dir>
2. Try skill:      /<plugin-name>:<skill-name>       (if skill created)
3. Author skill:   /superpowers:writing-skills       (to flesh out placeholder)
4. Add marketplace: /plugin marketplace add <marketplace-dir>
   Install:         /plugin install <plugin-name>@<marketplace-name>
```

---

## Security

| Constraint | Impl |
|---|---|
| No JSON injection | All user values via `jq --arg` |
| No path traversal | `realpath --canonicalize-missing` on all paths |
| No silent overwrites | Pre-write check on `plugin.json` and `marketplace.json` mutations |
| marketplace.json modification | Read → transform via `jq` → write atomically |

---

## Dependencies

| Dep | Check | Install |
|---|---|---|
| `jq` | `jq --version` | `apt install jq` / `brew install jq` |
| GNU `realpath` | `realpath --version` | pre-installed Linux; macOS: `brew install coreutils` |
| `claude` CLI | `command -v claude` | optional — only for validation step |

---

## What this skill does NOT do

- Full skill authoring — use `superpowers:writing-skills` after scaffolding
- Marketplace creation — use `marketplace-init` for that
- Plugin publishing / tagging — use `claude plugin tag`
- Adding agents, hooks, MCP servers — user does this manually post-scaffold
