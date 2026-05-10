---
name: marketplace-init
description: Use when initializing a new Claude Code plugin marketplace, setting up plugin distribution infrastructure, creating a plugin registry, or sharing and distributing Claude plugins with a team or publicly.
arguments: [name, dir, owner-name, owner-email, description]
argument-hint: [name] [dir] [owner-name] [owner-email] [description]
allowed-tools: Bash(bash *)
---

# Marketplace Init

## Overview

A marketplace is a registry that groups plugins for distribution. It lives in a `.claude-plugin/marketplace.json` file and lets users install plugins with `/plugin install <plugin>@<marketplace-name>`. This skill scaffolds that structure interactively, prompting for any fields not pre-supplied.

## When to Use

- Starting a new plugin marketplace from scratch
- Setting up plugin distribution for a team or project
- Creating a new plugin registry

## When NOT to Use

- Marketplace already exists at the target path — the script will error; use the existing file directly
- Adding plugins to an existing marketplace — edit `marketplace.json` directly
- Updating marketplace metadata — edit `marketplace.json` directly

## Prerequisites

| Dependency | Check | Install |
|------------|-------|---------|
| `jq` | `jq --version` | `apt install jq` / `brew install jq` |
| GNU `realpath` | `realpath --version` | pre-installed on Linux; macOS: `brew install coreutils` |

## Instructions

**Step 1 — Collect missing args.**

Identify which of the five fields are not pre-supplied. If any are missing, ask for all of them in a single message as a numbered list. Wait for the user's reply, then map answers to fields by order or by explicit field name if the user labels them. If `owner-email` is blank or skipped, omit `--owner-email` entirely.

**Step 2 — Run the script once with all args.**

```
bash "${CLAUDE_SKILL_DIR}/scripts/init.sh" \
  --name "$name" \
  --dir "$dir" \
  --owner-name "$owner_name" \
  [--owner-email "$owner_email"  ← omit if skipped] \
  --description "$description"
```

On non-zero exit, show the stderr output to the user. Ask whether they want to troubleshoot the error or cancel, and proceed accordingly.

On success, parse the JSON stdout for `dir`, `name`, and `path`. Display:

```
✓ Marketplace created at <path>

Next steps:
1. Validate:  claude plugin validate <dir>
2. Add:       /plugin marketplace add <dir>
3. Install:   /plugin install <plugin-name>@<name>

Add plugins to the plugins[] array in marketplace.json when ready.
```

## Example

```
/marketplace-init my-team-tools . "Acme Corp" tools@acme.com "Internal tools for Acme devs"
```

Equivalent to running `init.sh` with all five args pre-supplied — no interactive prompts.

## Common Mistakes

| Mistake | Error | Fix |
|---------|-------|-----|
| Reserved name (`agent-skills`, `anthropic-marketplace`, etc.) | `Invalid: '<name>' is a reserved name` | Choose a unique name — see `docs/schema.md` for the full reserved list |
| Name has uppercase / spaces / leading or trailing hyphen | `Invalid: must be lowercase letters, numbers, and hyphens only` | Use kebab-case: `my-team-tools` not `My Tools` |
| Target dir already has `marketplace.json` | `Error: marketplace already exists at <path>` | Edit the existing file; do not re-run init |
| `jq` not installed | `Error: jq is required` | `apt install jq` or `brew install jq` |
| GNU `realpath` missing (macOS) | `realpath: illegal option -- -` | `brew install coreutils` |

## Reference

- Schema fields and reserved names: [docs/schema.md](./docs/schema.md)
- Plugin source types: [docs/sources.md](docs/sources.md)
- Version management: [docs/versioning.md](docs/versioning.md)
- Validation and testing: [docs/validation.md](docs/validation.md)
- Hosting and team distribution: [docs/distribution.md](docs/distribution.md)
