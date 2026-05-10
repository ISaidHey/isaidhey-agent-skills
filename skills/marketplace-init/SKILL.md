---
name: marketplace-init
description: Set up a Claude Code plugin marketplace in a target directory. Use when creating a new marketplace, scaffolding marketplace structure, or initializing plugin distribution.
disable-model-invocation: true
arguments: [dir, name]
argument-hint: <dir> [marketplace-name]
allowed-tools: Bash(mkdir *) Bash(ls *) Write Read
---

# Marketplace Init

Set up a Claude Code plugin marketplace at `$dir`.

## Reference docs
- Schema fields and reserved names: [schema.md](docs/schema.md)
- Plugin source types: [sources.md](docs/sources.md)
- Version management: [versioning.md](docs/versioning.md)
- Validation and testing: [validation.md](docs/validation.md)

## Steps

### 1. Validate target directory

If `$dir` is empty, ask:

> "Where should the marketplace be created? (provide a directory path)"

Then check if a marketplace already exists at that path:

```bash
ls $dir/.claude-plugin/marketplace.json 2>/dev/null
```

If the file exists, stop with this message:

> "A marketplace already exists at `$dir/.claude-plugin/marketplace.json`. Aborting to avoid overwriting it."

### 2. Validate marketplace name

Use `$name` if provided. Otherwise, ask:

> "What should the marketplace be named? (kebab-case, e.g. `acme-tools`)"

Requirements (see docs/schema.md for reserved names list):
- Lowercase letters, numbers, hyphens only
- No spaces, no uppercase letters
- Not a reserved name

If invalid, explain the specific problem and ask again.

### 3. Collect owner name

Ask:

> "What is your name or team name? (shown as the marketplace maintainer)"

Required. Ask again if the user submits empty input.

### 4. Collect owner email

Ask:

> "Owner email address? (optional — press Enter to skip)"

Accept empty input and proceed.

### 5. Collect description

Ask:

> "Describe this marketplace in one sentence:"

Required. Ask again if the user submits empty input.

### 6. Create files

Run:

```bash
mkdir -p $dir/.claude-plugin
```

Write `$dir/.claude-plugin/marketplace.json` with the values collected above:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-marketplace.json",
  "name": "<collected-name>",
  "description": "<collected-description>",
  "version": "1.0.0",
  "owner": {
    "name": "<collected-owner-name>",
    "email": "<collected-email>"
  },
  "plugins": []
}
```

Omit the `"email"` line entirely if the user skipped it.

### 7. Show next steps

Print:

```
✓ Marketplace created at $dir/.claude-plugin/marketplace.json

Next steps:
1. Validate:  claude plugin validate $dir
2. Add:       /plugin marketplace add $dir
3. Install:   /plugin install <plugin-name>@<collected-name>

Version is set to "1.0.0". Bump it on each release, or remove it entirely
to track git commit SHA automatically (every commit = new version).

Add plugins to the plugins[] array in marketplace.json when ready.
```
