# Marketplace Init Skill — Design Spec

**Date:** 2026-05-09
**Branch:** feat/marketplace-skill

---

## Overview

A skill that scaffolds a Claude Code plugin marketplace in a user-specified directory. Walks the user through an interactive wizard to collect required metadata, then writes the directory structure and `marketplace.json`. Hosted in the `skills/plugin-marketplace/` directory of the `isaidhey-agent-skills` plugin repo.

**Out of scope:** plugin entry scaffolding (future skill), hosting/distribution setup (future skill), git init.

---

## File Structure

```
skills/plugin-marketplace/
├── SKILL.md                        # skill entrypoint — wizard instructions
├── docs/
│   ├── plugins.md                  # existing, untouched
│   ├── plugin-marketplaces.md      # existing, untouched
│   ├── plugin-dependencies.md      # existing, untouched
│   ├── plugins-reference.md        # existing, untouched
│   ├── schema.md                   # NEW — marketplace.json field reference
│   ├── sources.md                  # NEW — plugin source types with examples
│   ├── versioning.md               # NEW — version resolution and management
│   └── validation.md               # NEW — validate commands and common errors
```

---

## Skill Frontmatter

```yaml
---
name: marketplace-init
description: Set up a Claude Code plugin marketplace in a target directory. Use when creating a new marketplace, scaffolding marketplace structure, or initializing plugin distribution.
disable-model-invocation: true
arguments: [dir, name]
argument-hint: <dir> [marketplace-name]
allowed-tools: Bash(mkdir *) Bash(ls *) Write Read
---
```

- `disable-model-invocation: true` — user-triggered only; side effects warrant explicit invocation
- `arguments: [dir, name]` — `$dir` is the target directory, `$name` is the marketplace name (both positional)
- `allowed-tools` — only what's needed for dir checks and file creation

---

## Wizard Flow

```
1. Validate $dir
   └── if empty → ask user for directory
   └── if .claude-plugin/marketplace.json exists → abort with message

2. Validate $name
   └── if empty → ask user for marketplace name (kebab-case)
   └── validate format (lowercase, hyphens, no spaces)
   └── check against reserved names list

3. Ask: owner name (required)

4. Ask: owner email (optional — user can skip)

5. Ask: description (required)

6. Create files:
   └── mkdir -p $dir/.claude-plugin/
   └── write $dir/.claude-plugin/marketplace.json

7. Print next steps
```

---

## Generated Output

`$dir/.claude-plugin/marketplace.json`:

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

- `email` field omitted if user skipped it
- `version` defaults to `"1.0.0"` — next-steps message explains the explicit-vs-SHA choice
- `plugins` is an empty array — entries added via future `marketplace-plugin-add` skill

---

## Supporting Reference Files

Four condensed docs stored in `skills/plugin-marketplace/docs/`, generated as part of this task. Referenced from `SKILL.md` with markdown links so Claude loads them contextually during the wizard.

| File | Contents | Used at step |
|------|----------|-------------|
| `schema.md` | `marketplace.json` required + optional fields, owner fields, reserved names list | Steps 2–5 (field prompts) |
| `sources.md` | All source types (relative, github, url, git-subdir, npm) with minimal examples | Next steps output |
| `versioning.md` | Explicit version vs commit-SHA, when to bump, release channels | Next steps output |
| `validation.md` | `claude plugin validate`, install/test commands, common errors table | Step 7 (next steps) |

SKILL.md references them:

```markdown
## Reference docs
- Schema fields: [schema.md](docs/schema.md)
- Source types: [sources.md](docs/sources.md)
- Versioning: [versioning.md](docs/versioning.md)
- Validation: [validation.md](docs/validation.md)
```

---

## Next Steps Output (Step 7)

After file creation, Claude prints:

```
Marketplace scaffolded at <dir>/.claude-plugin/marketplace.json

Next steps:
1. Validate:  claude plugin validate <dir>
2. Add:       /plugin marketplace add <dir>
3. Test:      /plugin install <plugin-name>@<name>

Version defaults to "1.0.0". Bump it each release, or remove it to track
git commit SHA automatically (every commit = new version).

Add plugins to the plugins[] array when ready — or wait for the
marketplace-plugin-add skill.
```

---

## What This Skill Does NOT Do

- Init a git repo
- Add plugin entries
- Configure hosting or team distribution settings
- Validate the directory is inside a git repo

---

## Future Skills (Noted)

- `marketplace-plugin-add` — adds a plugin entry to an existing `marketplace.json`
- `marketplace-hosting` — guides GitHub/private git distribution setup, `extraKnownMarketplaces` snippet, token env vars
