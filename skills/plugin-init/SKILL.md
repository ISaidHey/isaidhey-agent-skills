---
name: plugin-init
description: Use when creating a new Claude Code plugin, scaffolding a plugin directory structure, initializing a new plugin with skills or agents, or setting up a plugin to distribute through a marketplace.
arguments: [name, dir, description, author-name, author-email, skill-name, skill-description]
argument-hint: "[name] [dir] [description] [author-name] [author-email] [skill-name] [skill-description]"
allowed-tools: Bash(bash *) Bash(claude *)
---

# Plugin Init

## Overview

Scaffolds a new Claude Code plugin directory with a `plugin.json` manifest. Optionally creates a first-skill placeholder and registers the plugin in a local marketplace.

## When to Use

- Creating a new plugin from scratch
- Adding a plugin to an existing marketplace
- Setting up plugin distribution infrastructure

## When NOT to Use

- Plugin already exists at target path — script will error; modify existing files directly
- Creating a marketplace — use `/marketplace-init` instead
- Authoring full skill content — use `/superpowers:writing-skills` after this skill creates the placeholder

## Prerequisites

| Dependency | Check | Install |
|---|---|---|
| `jq` | `jq --version` | `apt install jq` / `brew install jq` |
| GNU `realpath` | `realpath --version` | pre-installed Linux; macOS: `brew install coreutils` |
| `claude` CLI | `command -v claude` | optional — for post-creation validation only |

## Instructions

**Step 1 — Collect missing plugin fields.**

Check which of the following are not pre-supplied via `$ARGUMENTS`: `name`, `dir`, `description`. If any are missing, ask for all missing fields in a single numbered-list message. Include `author-name` and `author-email` as optional items in the same message. Wait for the user's reply, then map answers by position or by label.

**Step 2 — Create the plugin.**

```
bash "${CLAUDE_SKILL_DIR}/scripts/init.sh" \
  --name "$name" \
  --dir "$dir" \
  --description "$description" \
  [--author-name "$author_name"   ← omit if not supplied] \
  [--author-email "$author_email" ← omit if not supplied]
```

On non-zero exit: show stderr, ask whether to troubleshoot or cancel.
On success: parse stdout JSON, display `✓ Plugin created at <plugin_json>`.

**Step 3 — Offer first skill.**

Ask: "Want to add a first skill? Provide a name and description, or press Enter to skip."

> **Note:** This creates a minimal placeholder only (name, description, `TODO` body). For full skill authoring, use `/superpowers:writing-skills` after scaffolding.

If the user provides a skill name and optional description:

```
bash "${CLAUDE_SKILL_DIR}/scripts/init.sh" \
  --name "$name" \
  --dir "$dir" \
  --description "$description" \
  --no-create \
  --skill-name "$skill_name" \
  [--skill-description "$skill_description" ← omit if not provided]
```

On success: note `skill_created` from stdout JSON.

**Step 4 — Offer marketplace registration.**

Ask: "Register this plugin in a marketplace? (y/N)"

If yes, discover local marketplaces by injecting:

```
!`find . -maxdepth 4 -name "marketplace.json" -path "*/.claude-plugin/*" 2>/dev/null`
```

Present the discovery results:
- 0 found → ask user to enter the marketplace directory path
- 1 found → confirm: "Found marketplace at `<path>`. Register here? (Y/n)"
- 2+ found → numbered list, ask user to pick

Show the computed default relative source path (from marketplace dir to plugin dir) and let user confirm or provide an override.

```
bash "${CLAUDE_SKILL_DIR}/scripts/init.sh" \
  --name "$name" \
  --dir "$dir" \
  --description "$description" \
  --no-create \
  --register \
  --marketplace-dir "$marketplace_dir" \
  [--marketplace-source "$source" ← omit to use default relative path]
```

On success: note `registered` and `marketplace_name` from stdout JSON.

**Step 5 — Validate.**

Run:

```
bash -c 'command -v claude >/dev/null 2>&1 && claude plugin validate "$1" || echo SKIP' _ "$dir"
```

If output is `SKIP`: display "Skipping validation — `claude` CLI not found. Install Claude Code to validate."
If exit non-zero: show full output, ask whether to troubleshoot or cancel.
If exit 0: show validation output.

**Step 6 — Display result.**

```
✓ Plugin created at <plugin_json>
✓ Skill placeholder created: <skill_created>    (if applicable)
✓ Registered in <marketplace_name>              (if applicable)

Validation passed.                              (if validation ran and passed)

Next steps:
1. Test locally:    claude --plugin-dir <dir>
2. Try skill:       /<name>:<skill_created>         (if skill was created)
3. Author skill:    /superpowers:writing-skills      (to flesh out the placeholder)
4. Add marketplace: /plugin marketplace add <marketplace_dir>
   Install:         /plugin install <name>@<marketplace_name>
```

## Example

```
/plugin-init my-plugin . "My awesome plugin" "Jane Smith" jane@example.com my-first-skill "Does something useful"
```

All fields pre-supplied — no interactive prompts for Steps 1–3; still asks about marketplace in Step 4.

## Common Mistakes

| Mistake | Error | Fix |
|---|---|---|
| Invalid name format | `Invalid: name must be lowercase...` | Use kebab-case: `my-plugin` not `My Plugin` |
| Plugin already exists at dir | `Error: plugin already exists at...` | Use `--no-create` to add skill/register to existing plugin |
| `--register` without `--marketplace-dir` | `Error: --marketplace-dir is required` | Supply `--marketplace-dir` |
| Plugin name already in marketplace | `Error: plugin '...' is already registered` | Plugin already registered — edit `marketplace.json` directly |
| `jq` not installed | `Error: jq is required` | `apt install jq` / `brew install jq` |
| GNU `realpath` missing (macOS) | `realpath: illegal option` | `brew install coreutils` |
