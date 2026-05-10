# Marketplace Init Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `marketplace-init` skill and 4 condensed reference docs that walk a user through scaffolding a Claude Code plugin marketplace.

**Architecture:** One `SKILL.md` (inline wizard, user-invocable only) + 4 supporting reference docs distilled from existing source docs. All files land in `skills/plugin-marketplace/`. Existing docs are never modified.

**Tech Stack:** Claude Code skill system (SKILL.md frontmatter + markdown), no build step, no dependencies.

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `skills/plugin-marketplace/SKILL.md` | Skill entrypoint — wizard instructions |
| Create | `skills/plugin-marketplace/docs/schema.md` | `marketplace.json` field reference + reserved names |
| Create | `skills/plugin-marketplace/docs/sources.md` | Plugin source types with minimal examples |
| Create | `skills/plugin-marketplace/docs/versioning.md` | Explicit version vs commit-SHA, release channels |
| Create | `skills/plugin-marketplace/docs/validation.md` | Validate commands + common errors table |
| Leave untouched | `skills/plugin-marketplace/docs/plugins.md` | Existing source doc |
| Leave untouched | `skills/plugin-marketplace/docs/plugin-marketplaces.md` | Existing source doc |
| Leave untouched | `skills/plugin-marketplace/docs/plugin-dependencies.md` | Existing source doc |
| Leave untouched | `skills/plugin-marketplace/docs/plugins-reference.md` | Existing source doc |

---

## Task 1: Create `schema.md`

**Files:**
- Create: `skills/plugin-marketplace/docs/schema.md`

- [ ] **Step 1: Write the file**

Create `skills/plugin-marketplace/docs/schema.md` with this exact content:

```markdown
# Marketplace Schema Reference

## Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Kebab-case identifier. Used in install commands: `/plugin install my-plugin@name`. |
| `owner` | object | Maintainer info — see Owner Fields below |
| `plugins` | array | List of plugin entries (can be empty `[]`) |

## Owner Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Name of maintainer or team |
| `email` | No | Contact email |

## Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `$schema` | string | JSON Schema URL for editor autocomplete. Ignored by Claude Code at load time. Use `"https://json.schemastore.org/claude-code-marketplace.json"` |
| `description` | string | Brief marketplace description |
| `version` | string | Marketplace manifest version |
| `metadata.pluginRoot` | string | Base dir prepended to relative plugin source paths. E.g. `"./plugins"` lets you write `"source": "formatter"` instead of `"source": "./plugins/formatter"` |
| `allowCrossMarketplaceDependenciesOn` | array | Marketplace names whose plugins can be auto-installed as dependencies |

## Reserved Names

These cannot be used for third-party marketplaces (enforced at submission):

- `claude-code-marketplace`
- `claude-code-plugins`
- `claude-plugins-official`
- `anthropic-marketplace`
- `anthropic-plugins`
- `agent-skills`
- `knowledge-work-plugins`
- `life-sciences`

Names that impersonate official marketplaces (e.g. `official-claude-plugins`, `anthropic-tools-v2`) are also blocked.
```

- [ ] **Step 2: Verify**

Read the file back and confirm:
- Table renders with correct columns
- All 8 reserved names present
- No placeholder text

---

## Task 2: Create `sources.md`

**Files:**
- Create: `skills/plugin-marketplace/docs/sources.md`

- [ ] **Step 1: Write the file**

Create `skills/plugin-marketplace/docs/sources.md` with this exact content:

````markdown
# Plugin Source Types

Each plugin entry in `plugins[]` requires `name` and `source`. The `source` field tells Claude Code where to fetch the plugin. Once fetched, plugins are cached at `~/.claude/plugins/cache`.

## Relative Path

For plugins in the same repository. Must start with `./`. Resolves relative to the marketplace root (the directory containing `.claude-plugin/`).

```json
{ "name": "my-plugin", "source": "./plugins/my-plugin" }
```

> Only works when the marketplace is added via Git. Fails with URL-based marketplaces (the JSON file is fetched but the relative files aren't).

## GitHub

```json
{
  "name": "my-plugin",
  "source": {
    "source": "github",
    "repo": "owner/repo",
    "ref": "v2.0.0",
    "sha": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
  }
}
```

`ref` (branch/tag) and `sha` (exact commit) are optional. Both omitted = default branch.

## Git URL

Works with GitLab, Bitbucket, self-hosted, or any HTTPS/SSH git remote.

```json
{
  "name": "my-plugin",
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git",
    "ref": "main"
  }
}
```

## Git Subdirectory (monorepo)

Sparse clone — fetches only the named subdirectory. Minimises bandwidth for large monorepos.

```json
{
  "name": "my-plugin",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/org/monorepo.git",
    "path": "tools/my-plugin",
    "ref": "v2.0.0"
  }
}
```

## npm

```json
{
  "name": "my-plugin",
  "source": {
    "source": "npm",
    "package": "@acme/claude-plugin",
    "version": "2.1.0",
    "registry": "https://npm.example.com"
  }
}
```

`version` (semver or range) and `registry` (private registry URL) are optional.
````

- [ ] **Step 2: Verify**

Read the file back and confirm:
- All 5 source types present (relative, github, url, git-subdir, npm)
- Each has a JSON example
- No placeholder text

---

## Task 3: Create `versioning.md`

**Files:**
- Create: `skills/plugin-marketplace/docs/versioning.md`

- [ ] **Step 1: Write the file**

Create `skills/plugin-marketplace/docs/versioning.md` with this exact content:

```markdown
# Version Management

## Resolution Order

Claude Code picks the plugin's version from the first of these that is set:

1. `version` in the plugin's `plugin.json`
2. `version` in the plugin's marketplace entry (`marketplace.json`)
3. Git commit SHA of the plugin's source (for git-backed sources)
4. `"unknown"` — for npm sources or local dirs not inside a git repo

## Two Approaches

### Explicit version (stable releases)

Set `"version": "1.0.0"` in `plugin.json` or the marketplace entry.

- Users receive updates **only when you bump this field**
- Pushing new commits without bumping has no effect
- Best for published plugins with stable release cycles

Follow semver: MAJOR for breaking changes, MINOR for new features, PATCH for fixes.

> **Warning:** If both `plugin.json` and the marketplace entry set `version`, `plugin.json` wins silently. Set it in one place only.

### Commit-SHA version (active development)

Omit `version` from both `plugin.json` and the marketplace entry.

- Every new commit is a new version
- Users get updates on every push
- Best for internal or team plugins under active development

## Release Channels

To support stable/latest channels, create two marketplace files pointing to different `ref` values of the same repo:

```json
{ "name": "stable-tools", "plugins": [{ "name": "formatter", "source": { "source": "github", "repo": "org/formatter", "ref": "stable" } }] }
{ "name": "latest-tools", "plugins": [{ "name": "formatter", "source": { "source": "github", "repo": "org/formatter", "ref": "latest" } }] }
```

Each channel must resolve to a different version string — otherwise auto-update skips it as already installed.
```

- [ ] **Step 2: Verify**

Read the file back and confirm:
- Resolution order numbered list present
- Both approaches (explicit + commit-SHA) documented
- Warning about duplicate version fields present

---

## Task 4: Create `validation.md`

**Files:**
- Create: `skills/plugin-marketplace/docs/validation.md`

- [ ] **Step 1: Write the file**

Create `skills/plugin-marketplace/docs/validation.md` with this exact content:

```markdown
# Validation and Testing

## Validate Your Marketplace

From the marketplace directory:

```bash
claude plugin validate .
```

Or from within Claude Code:

```
/plugin validate .
```

Checks `plugin.json`, skill/agent/command frontmatter, and `hooks/hooks.json` for syntax and schema errors. Safe to run repeatedly.

## Add and Test

```bash
# Add via CLI
claude plugin marketplace add ./my-marketplace

# Add from within Claude Code
/plugin marketplace add ./my-marketplace

# Install a plugin from it
/plugin install my-plugin@my-marketplace-name

# List installed plugins
claude plugin list
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `File not found: .claude-plugin/marketplace.json` | Missing manifest | Create `.claude-plugin/marketplace.json` with required fields |
| `Invalid JSON syntax: Unexpected token...` | JSON parse error | Check for missing/extra commas, unquoted strings |
| `Duplicate plugin name "x" found in marketplace` | Two entries share same `name` | Give each plugin a unique `name` |
| `plugins[0].source: Path contains ".."` | Source path traverses outside marketplace root | Use paths relative to marketplace root without `..` |
| `YAML frontmatter failed to parse: ...` | Invalid YAML in a skill or agent file | Fix the YAML syntax; the file loads with no metadata at runtime |
| `Invalid JSON syntax: ...` (hooks.json) | Malformed `hooks/hooks.json` | Fix JSON — a malformed hooks.json blocks the entire plugin from loading |

## Non-Blocking Warnings

- `Marketplace has no plugins defined` — add at least one entry to `plugins[]`
- `No marketplace description provided` — add top-level `description`
- `Plugin name "x" is not kebab-case` — rename to lowercase letters, digits, and hyphens only (required for Claude.ai marketplace submission)
```

- [ ] **Step 2: Verify**

Read the file back and confirm:
- validate command shown for both CLI and in-app
- 6 error rows in table
- 3 non-blocking warnings listed

---

## Task 5: Create `SKILL.md`

**Files:**
- Create: `skills/plugin-marketplace/SKILL.md`

- [ ] **Step 1: Write the file**

Create `skills/plugin-marketplace/SKILL.md` with this exact content:

````markdown
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

Use `$name` if provided. Otherwise ask:

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
````

- [ ] **Step 2: Verify structure**

Confirm:
- Frontmatter is valid YAML (between `---` markers)
- `arguments: [dir, name]` matches `$dir` and `$name` usage in body
- All 4 reference doc links present
- 7 numbered steps present
- `disable-model-invocation: true` present
- File is under 500 lines

---

## Task 6: Commit

**Files:** All 5 new files

- [ ] **Step 1: Stage new files**

```bash
git status
```

Confirm 5 new files appear:
- `skills/plugin-marketplace/SKILL.md`
- `skills/plugin-marketplace/docs/schema.md`
- `skills/plugin-marketplace/docs/sources.md`
- `skills/plugin-marketplace/docs/versioning.md`
- `skills/plugin-marketplace/docs/validation.md`

Also confirm existing docs are NOT modified:
- `skills/plugin-marketplace/docs/plugins.md` — unchanged
- `skills/plugin-marketplace/docs/plugin-marketplaces.md` — unchanged
- `skills/plugin-marketplace/docs/plugin-dependencies.md` — unchanged
- `skills/plugin-marketplace/docs/plugins-reference.md` — unchanged

- [ ] **Step 2: Commit**

```bash
git commit -am "feat: add marketplace-init skill with condensed reference docs"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered by |
|-----------------|------------|
| `SKILL.md` with correct frontmatter | Task 5 |
| `arguments: [dir, name]` + `argument-hint` | Task 5 Step 1 |
| `disable-model-invocation: true` | Task 5 Step 1 |
| `allowed-tools` | Task 5 Step 1 |
| Validate dir exists / abort if marketplace present | Task 5 Step 1, wizard step 1 |
| Name validation (kebab-case + reserved names) | Task 5 wizard step 2 |
| Owner name required | Task 5 wizard step 3 |
| Owner email optional | Task 5 wizard step 4 |
| Description required | Task 5 wizard step 5 |
| `mkdir -p .claude-plugin` | Task 5 wizard step 6 |
| `marketplace.json` with all fields incl. `version: "1.0.0"` | Task 5 wizard step 6 |
| Email omitted if not provided | Task 5 wizard step 6 |
| Next steps output with version note | Task 5 wizard step 7 |
| `schema.md` with fields + reserved names | Task 1 |
| `sources.md` with all 5 source types | Task 2 |
| `versioning.md` with both approaches | Task 3 |
| `validation.md` with errors table | Task 4 |
| Markdown links to all 4 reference docs | Task 5 Step 1 |
| Existing docs untouched | Task 6 Step 1 (verified in git status) |

All requirements covered. No gaps found.
