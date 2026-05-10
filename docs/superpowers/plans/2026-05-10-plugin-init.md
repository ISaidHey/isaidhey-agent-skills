# plugin-init Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `skills/plugin-init/` — a two-file skill (SKILL.md + scripts/init.sh) that scaffolds a new Claude Code plugin directory with optional first-skill placeholder and optional marketplace registration.

**Architecture:** Single bash script (`init.sh`) with three isolated functions (`create_plugin`, `create_skill`, `register_plugin`) controlled by flags. SKILL.md drives a multi-step conversation: collect fields → create plugin → optionally add skill placeholder → optionally register in marketplace → validate. Mirrors the `marketplace-init` skill structure exactly.

**Tech Stack:** Bash, `jq` (JSON writes/transforms), GNU `realpath` (path canonicalization), `claude` CLI (optional, post-creation validation only)

---

## File Map

| File | Status | Responsibility |
|---|---|---|
| `skills/plugin-init/SKILL.md` | Create | Conversation flow, arg collection, script orchestration |
| `skills/plugin-init/scripts/init.sh` | Create | All file I/O: plugin.json creation, SKILL.md placeholder, marketplace.json mutation |

**Reference (read-only during implementation):**
- `skills/marketplace-init/scripts/init.sh` — model for script conventions
- `skills/marketplace-init/SKILL.md` — model for SKILL.md conventions
- `docs/superpowers/specs/2026-05-10-plugin-init-design.md` — full spec

---

## Task 1: Directory structure and script skeleton

**Files:**
- Create: `skills/plugin-init/SKILL.md` (placeholder — replaced in Task 6)
- Create: `skills/plugin-init/scripts/init.sh`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /workspace/skills/plugin-init/scripts
```

- [ ] **Step 2: Create placeholder SKILL.md** (keeps skill directory valid; replaced in Task 6)

Write `skills/plugin-init/SKILL.md`:

```markdown
---
name: plugin-init
description: placeholder
---

placeholder
```

- [ ] **Step 3: Write init.sh skeleton**

Write `skills/plugin-init/scripts/init.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

command -v jq      >/dev/null 2>&1 || { echo "Error: jq is required. Install: apt install jq / brew install jq" >&2; exit 1; }
realpath --version >/dev/null 2>&1 || { echo "Error: GNU realpath is required. Install: brew install coreutils (macOS)" >&2; exit 1; }

OPT_NAME=""
OPT_DIR=""
OPT_DESCRIPTION=""
OPT_AUTHOR_NAME=""
OPT_AUTHOR_EMAIL=""
OPT_SKILL_NAME=""
OPT_SKILL_DESCRIPTION=""
OPT_REGISTER=false
OPT_MARKETPLACE_DIR=""
OPT_MARKETPLACE_SOURCE=""
OPT_NO_CREATE=false

usage() {
  cat >&2 <<'EOF'
Usage: init.sh [OPTIONS]

Options:
  --name NAME              Plugin name (kebab-case)
  --dir DIR                Target directory
  --description DESC       Plugin description
  --author-name NAME       Author name (optional)
  --author-email EMAIL     Author email (optional)
  --skill-name NAME        First skill name (optional)
  --skill-description D    First skill description (optional)
  --register               Register plugin in a marketplace
  --marketplace-dir DIR    Marketplace root (required with --register)
  --marketplace-source S   Override default relative source path (optional)
  --no-create              Skip plugin creation (add skill/register only)
  -h, --help               Show this help
EOF
  exit 1
}

need_arg() { [[ $# -ge 2 ]] || { echo "Error: $1 requires a value" >&2; usage; }; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)               need_arg "$@"; OPT_NAME="$2";               shift 2 ;;
    --dir)                need_arg "$@"; OPT_DIR="$2";                shift 2 ;;
    --description)        need_arg "$@"; OPT_DESCRIPTION="$2";        shift 2 ;;
    --author-name)        need_arg "$@"; OPT_AUTHOR_NAME="$2";        shift 2 ;;
    --author-email)       need_arg "$@"; OPT_AUTHOR_EMAIL="$2";       shift 2 ;;
    --skill-name)         need_arg "$@"; OPT_SKILL_NAME="$2";         shift 2 ;;
    --skill-description)  need_arg "$@"; OPT_SKILL_DESCRIPTION="$2";  shift 2 ;;
    --marketplace-dir)    need_arg "$@"; OPT_MARKETPLACE_DIR="$2";    shift 2 ;;
    --marketplace-source) need_arg "$@"; OPT_MARKETPLACE_SOURCE="$2"; shift 2 ;;
    --register)           OPT_REGISTER=true;                          shift ;;
    --no-create)          OPT_NO_CREATE=true;                         shift ;;
    -h|--help)            usage ;;
    *)                    echo "Unknown option: $1" >&2; usage ;;
  esac
done

# Required args
[[ -z "$OPT_NAME" ]]        && { echo "Error: --name is required" >&2; exit 1; }
[[ -z "$OPT_DIR" ]]         && { echo "Error: --dir is required" >&2; exit 1; }
[[ -z "$OPT_DESCRIPTION" ]] && { echo "Error: --description is required" >&2; exit 1; }
[[ "$OPT_REGISTER" == true && -z "$OPT_MARKETPLACE_DIR" ]] && {
  echo "Error: --marketplace-dir is required when --register is set" >&2; exit 1
}

# Name validation (applies to plugin name; used as namespace and dir name)
if [[ ! "$OPT_NAME" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
  echo "Invalid: name must be lowercase letters, numbers, and hyphens only (e.g. my-plugin)" >&2
  exit 1
fi

# Resolve plugin dir once; all functions use $DIR
DIR="$(realpath --canonicalize-missing -- "$OPT_DIR")"

# Result variables — written by functions, assembled into JSON at end
RESULT_NAME="$OPT_NAME"
RESULT_DIR="$DIR"
RESULT_PLUGIN_JSON="$DIR/.claude-plugin/plugin.json"
RESULT_SKILL_CREATED=""
RESULT_REGISTERED=false
RESULT_MARKETPLACE_NAME=""
RESULT_MARKETPLACE_DIR_OUT=""
```

- [ ] **Step 4: Verify --help exits cleanly**

```bash
bash /workspace/skills/plugin-init/scripts/init.sh --help 2>&1; echo "exit: $?"
```

Expected: prints usage block to stderr, `exit: 1`.

- [ ] **Step 5: Verify unknown option is rejected**

```bash
bash /workspace/skills/plugin-init/scripts/init.sh --unknown 2>&1; echo "exit: $?"
```

Expected output contains `Unknown option: --unknown`, `exit: 1`.

- [ ] **Step 6: Verify missing required arg is caught**

```bash
bash /workspace/skills/plugin-init/scripts/init.sh --name foo --dir /tmp 2>&1; echo "exit: $?"
```

Expected: `Error: --description is required`, `exit: 1`.

- [ ] **Step 7: Verify invalid name is caught**

```bash
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name "Bad Name" --dir /tmp --description "test" 2>&1; echo "exit: $?"
```

Expected: `Invalid: name must be lowercase letters, numbers, and hyphens only`, `exit: 1`.

- [ ] **Step 8: Commit**

```bash
git -C /workspace add skills/plugin-init/
git -C /workspace commit -m "feat(plugin-init): add script skeleton with arg parsing and validation"
```

---

## Task 2: `create_plugin` function

**Files:**
- Modify: `skills/plugin-init/scripts/init.sh`

- [ ] **Step 1: Write the failing test** (run before implementing — expect no files created)

```bash
DIR=/tmp/test-cp-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "test" 2>&1; echo "exit: $?"
ls "$DIR" 2>&1
```

Expected: script exits with error or 0 but no files created (no functions wired yet).

- [ ] **Step 2: Add `create_plugin` function and stubs for the other two**

Append to `skills/plugin-init/scripts/init.sh` (after the result variables block):

```bash
# ---------------------------------------------------------------------------
create_plugin() {
  local plugin_json="$DIR/.claude-plugin/plugin.json"

  if [[ -f "$plugin_json" ]]; then
    echo "Error: plugin already exists at $plugin_json" >&2
    exit 1
  fi

  mkdir -p "$DIR/.claude-plugin"

  if [[ -n "$OPT_AUTHOR_NAME" && -n "$OPT_AUTHOR_EMAIL" ]]; then
    jq -n \
      --arg name  "$OPT_NAME" \
      --arg desc  "$OPT_DESCRIPTION" \
      --arg aname "$OPT_AUTHOR_NAME" \
      --arg email "$OPT_AUTHOR_EMAIL" \
      '{"name":$name,"description":$desc,"version":"1.0.0","author":{"name":$aname,"email":$email}}' \
      > "$plugin_json"
  elif [[ -n "$OPT_AUTHOR_NAME" ]]; then
    jq -n \
      --arg name  "$OPT_NAME" \
      --arg desc  "$OPT_DESCRIPTION" \
      --arg aname "$OPT_AUTHOR_NAME" \
      '{"name":$name,"description":$desc,"version":"1.0.0","author":{"name":$aname}}' \
      > "$plugin_json"
  else
    jq -n \
      --arg name "$OPT_NAME" \
      --arg desc "$OPT_DESCRIPTION" \
      '{"name":$name,"description":$desc,"version":"1.0.0"}' \
      > "$plugin_json"
  fi

  RESULT_PLUGIN_JSON="$plugin_json"
}

# Stubs — replaced in Tasks 3 and 4
create_skill()    { :; }
register_plugin() { :; }

# ---------------------------------------------------------------------------
# Main flow
[[ "$OPT_NO_CREATE" == false ]] && create_plugin
[[ -n "$OPT_SKILL_NAME" ]]      && create_skill
[[ "$OPT_REGISTER" == true ]]   && register_plugin

# ---------------------------------------------------------------------------
# Emit result JSON
jq -n \
  --arg  dir              "$RESULT_DIR" \
  --arg  name             "$RESULT_NAME" \
  --arg  plugin_json      "$RESULT_PLUGIN_JSON" \
  --arg  skill_created    "$RESULT_SKILL_CREATED" \
  --arg  registered       "$RESULT_REGISTERED" \
  --arg  marketplace_name "$RESULT_MARKETPLACE_NAME" \
  --arg  marketplace_dir  "$RESULT_MARKETPLACE_DIR_OUT" \
  '{
    dir:              $dir,
    name:             $name,
    plugin_json:      $plugin_json,
    skill_created:    (if $skill_created    == "" then null else $skill_created    end),
    registered:       ($registered == "true"),
    marketplace_name: (if $marketplace_name == "" then null else $marketplace_name end),
    marketplace_dir:  (if $marketplace_dir  == "" then null else $marketplace_dir  end)
  }'
```

- [ ] **Step 3: Test — no author fields**

```bash
DIR=/tmp/test-cp-noauthor-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "My test plugin"
cat "$DIR/.claude-plugin/plugin.json"
```

Expected:
```json
{
  "name": "my-plugin",
  "description": "My test plugin",
  "version": "1.0.0"
}
```

- [ ] **Step 4: Test — author name only**

```bash
DIR=/tmp/test-cp-aname-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "My test plugin" \
  --author-name "Test User"
cat "$DIR/.claude-plugin/plugin.json"
```

Expected:
```json
{
  "name": "my-plugin",
  "description": "My test plugin",
  "version": "1.0.0",
  "author": { "name": "Test User" }
}
```

- [ ] **Step 5: Test — both author fields**

```bash
DIR=/tmp/test-cp-both-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "My test plugin" \
  --author-name "Test User" --author-email "test@example.com"
cat "$DIR/.claude-plugin/plugin.json"
```

Expected:
```json
{
  "name": "my-plugin",
  "description": "My test plugin",
  "version": "1.0.0",
  "author": { "name": "Test User", "email": "test@example.com" }
}
```

- [ ] **Step 6: Test — duplicate plugin rejected**

```bash
DIR=/tmp/test-cp-dup-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "first"
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "second" 2>&1; echo "exit: $?"
```

Expected: `Error: plugin already exists at .../plugin.json`, `exit: 1`.

- [ ] **Step 7: Verify stdout is valid JSON with correct null fields**

```bash
DIR=/tmp/test-cp-json-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "test" | jq .
```

Expected:
```json
{
  "dir": "/tmp/test-cp-json-...",
  "name": "my-plugin",
  "plugin_json": "/tmp/test-cp-json-.../.claude-plugin/plugin.json",
  "skill_created": null,
  "registered": false,
  "marketplace_name": null,
  "marketplace_dir": null
}
```

- [ ] **Step 8: Commit**

```bash
git -C /workspace add skills/plugin-init/scripts/init.sh
git -C /workspace commit -m "feat(plugin-init): implement create_plugin function"
```

---

## Task 3: `create_skill` function

**Files:**
- Modify: `skills/plugin-init/scripts/init.sh`

- [ ] **Step 1: Write the failing test** (stub does nothing — directory won't be created)

```bash
DIR=/tmp/test-cs-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "test" \
  --skill-name my-skill --skill-description "Does something"
ls "$DIR/skills/" 2>&1
```

Expected: `ls: cannot access .../skills/: No such file or directory` (stub is a no-op).

- [ ] **Step 2: Replace `create_skill` stub with implementation**

Find the line `create_skill()    { :; }` and replace it with:

```bash
create_skill() {
  if [[ ! "$OPT_SKILL_NAME" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
    echo "Invalid: skill name must be lowercase letters, numbers, and hyphens only" >&2
    exit 1
  fi

  local skill_dir="$DIR/skills/$OPT_SKILL_NAME"
  mkdir -p "$skill_dir"

  local skill_desc="${OPT_SKILL_DESCRIPTION:-${OPT_SKILL_NAME} skill}"

  printf '%s\n' \
    "---" \
    "name: $OPT_SKILL_NAME" \
    "description: $skill_desc" \
    "disable-model-invocation: true" \
    "---" \
    "" \
    "# $OPT_SKILL_NAME" \
    "" \
    "TODO: Add skill instructions here." \
    > "$skill_dir/SKILL.md"

  RESULT_SKILL_CREATED="$OPT_SKILL_NAME"
}
```

- [ ] **Step 3: Re-run failing test — skill directory should now exist**

```bash
DIR=/tmp/test-cs2-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "test" \
  --skill-name my-skill --skill-description "Does something"
cat "$DIR/skills/my-skill/SKILL.md"
```

Expected:
```
---
name: my-skill
description: Does something
disable-model-invocation: true
---

# my-skill

TODO: Add skill instructions here.
```

- [ ] **Step 4: Test — default description when --skill-description omitted**

```bash
DIR=/tmp/test-cs-noesc-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "test" \
  --skill-name my-skill
head -4 "$DIR/skills/my-skill/SKILL.md"
```

Expected:
```
---
name: my-skill
description: my-skill skill
disable-model-invocation: true
```

- [ ] **Step 5: Test — invalid skill name rejected**

```bash
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir /tmp/x$$ --description "test" \
  --skill-name "Bad Skill" 2>&1; echo "exit: $?"
```

Expected: `Invalid: skill name must be lowercase letters, numbers, and hyphens only`, `exit: 1`.

- [ ] **Step 6: Verify `skill_created` in stdout JSON**

```bash
DIR=/tmp/test-cs-json-$$
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$DIR" --description "test" \
  --skill-name my-skill | jq '.skill_created'
```

Expected: `"my-skill"`

- [ ] **Step 7: Commit**

```bash
git -C /workspace add skills/plugin-init/scripts/init.sh
git -C /workspace commit -m "feat(plugin-init): implement create_skill function"
```

---

## Task 4: `register_plugin` function

**Files:**
- Modify: `skills/plugin-init/scripts/init.sh`

- [ ] **Step 1: Create a test marketplace for this task**

```bash
MARKET_DIR=/tmp/test-reg-market-$$
bash /workspace/skills/marketplace-init/scripts/init.sh \
  --name test-market --dir "$MARKET_DIR" \
  --owner-name "Test Owner" --description "Test marketplace"
cat "$MARKET_DIR/.claude-plugin/marketplace.json"
```

Expected: valid marketplace.json with `"plugins": []`.

- [ ] **Step 2: Write the failing test** (stub does nothing — plugins array stays empty)

```bash
PLUGIN_DIR=/tmp/test-reg-plugin-$$
MARKET_DIR=/tmp/test-reg-market2-$$
bash /workspace/skills/marketplace-init/scripts/init.sh \
  --name test-market --dir "$MARKET_DIR" \
  --owner-name "Test" --description "Test market"
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$PLUGIN_DIR" --description "My plugin" \
  --register --marketplace-dir "$MARKET_DIR"
jq '.plugins' "$MARKET_DIR/.claude-plugin/marketplace.json"
```

Expected: `[]` (stub does nothing).

- [ ] **Step 3: Replace `register_plugin` stub with implementation**

Find the line `register_plugin() { :; }` and replace it with:

```bash
register_plugin() {
  local marketplace_json="$OPT_MARKETPLACE_DIR/.claude-plugin/marketplace.json"

  if [[ ! -f "$marketplace_json" ]]; then
    echo "Error: marketplace.json not found at $marketplace_json" >&2
    exit 1
  fi

  # Reject duplicate plugin name
  local existing
  existing=$(jq -r --arg n "$OPT_NAME" '.plugins[] | select(.name == $n) | .name' "$marketplace_json")
  if [[ -n "$existing" ]]; then
    echo "Error: plugin '$OPT_NAME' is already registered in this marketplace" >&2
    exit 1
  fi

  # Determine source: use override if provided, else compute relative path
  local source
  if [[ -n "$OPT_MARKETPLACE_SOURCE" ]]; then
    source="$OPT_MARKETPLACE_SOURCE"
  else
    local rel
    rel="$(realpath --relative-to="$OPT_MARKETPLACE_DIR" "$DIR")"
    source="./$rel"
  fi

  # Append plugin entry to marketplace.json
  local updated
  updated=$(jq \
    --arg name "$OPT_NAME" \
    --arg src  "$source" \
    --arg desc "$OPT_DESCRIPTION" \
    '.plugins += [{"name":$name,"source":$src,"description":$desc}]' \
    "$marketplace_json")
  echo "$updated" > "$marketplace_json"

  RESULT_REGISTERED=true
  RESULT_MARKETPLACE_NAME="$(jq -r '.name' "$marketplace_json")"
  RESULT_MARKETPLACE_DIR_OUT="$(realpath --canonicalize-missing -- "$OPT_MARKETPLACE_DIR")"
}
```

- [ ] **Step 4: Re-run failing test — plugin should now be in marketplace**

```bash
PLUGIN_DIR=/tmp/test-reg2-plugin-$$
MARKET_DIR=/tmp/test-reg2-market-$$
bash /workspace/skills/marketplace-init/scripts/init.sh \
  --name test-market --dir "$MARKET_DIR" \
  --owner-name "Test" --description "Test market"
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$PLUGIN_DIR" --description "My plugin" \
  --register --marketplace-dir "$MARKET_DIR"
jq '.plugins' "$MARKET_DIR/.claude-plugin/marketplace.json"
```

Expected:
```json
[
  {
    "name": "my-plugin",
    "source": "./<relative-path-from-market-to-plugin>",
    "description": "My plugin"
  }
]
```

- [ ] **Step 5: Test — missing marketplace.json is caught**

```bash
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir /tmp/p$$ --description "test" \
  --register --marketplace-dir /tmp/nonexistent-$$ 2>&1; echo "exit: $?"
```

Expected: `Error: marketplace.json not found at ...`, `exit: 1`.

- [ ] **Step 6: Test — duplicate plugin is rejected**

```bash
PLUGIN_DIR=/tmp/test-dup-plugin-$$
MARKET_DIR=/tmp/test-dup-market-$$
bash /workspace/skills/marketplace-init/scripts/init.sh \
  --name test-market --dir "$MARKET_DIR" \
  --owner-name "Test" --description "Test market"
# First registration (create plugin + register)
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$PLUGIN_DIR" --description "My plugin" \
  --register --marketplace-dir "$MARKET_DIR"
# Second registration (skip create, register only) — should fail
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$PLUGIN_DIR" --description "My plugin" \
  --no-create --register --marketplace-dir "$MARKET_DIR" 2>&1; echo "exit: $?"
```

Expected: `Error: plugin 'my-plugin' is already registered in this marketplace`, `exit: 1`.

- [ ] **Step 7: Test — custom --marketplace-source is used verbatim**

```bash
PLUGIN_DIR=/tmp/test-src-plugin-$$
MARKET_DIR=/tmp/test-src-market-$$
bash /workspace/skills/marketplace-init/scripts/init.sh \
  --name test-market --dir "$MARKET_DIR" \
  --owner-name "Test" --description "Test market"
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$PLUGIN_DIR" --description "My plugin" \
  --register --marketplace-dir "$MARKET_DIR" \
  --marketplace-source "./custom/path/my-plugin"
jq '.plugins[0].source' "$MARKET_DIR/.claude-plugin/marketplace.json"
```

Expected: `"./custom/path/my-plugin"`

- [ ] **Step 8: Verify stdout JSON reflects registration**

```bash
PLUGIN_DIR=/tmp/test-rj-plugin-$$
MARKET_DIR=/tmp/test-rj-market-$$
bash /workspace/skills/marketplace-init/scripts/init.sh \
  --name test-market --dir "$MARKET_DIR" \
  --owner-name "Test" --description "Test market"
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir "$PLUGIN_DIR" --description "My plugin" \
  --register --marketplace-dir "$MARKET_DIR" | jq '{registered,marketplace_name}'
```

Expected:
```json
{
  "registered": true,
  "marketplace_name": "test-market"
}
```

- [ ] **Step 9: Commit**

```bash
git -C /workspace add skills/plugin-init/scripts/init.sh
git -C /workspace commit -m "feat(plugin-init): implement register_plugin function"
```

---

## Task 5: End-to-end combined test

**Files:** No changes — verifies all three functions work together in a single invocation.

- [ ] **Step 1: Run all three flows in one invocation**

```bash
PLUGIN_DIR=/tmp/test-e2e-plugin-$$
MARKET_DIR=/tmp/test-e2e-market-$$

bash /workspace/skills/marketplace-init/scripts/init.sh \
  --name e2e-market --dir "$MARKET_DIR" \
  --owner-name "E2E Test" --description "E2E test marketplace"

OUTPUT=$(bash /workspace/skills/plugin-init/scripts/init.sh \
  --name e2e-plugin \
  --dir "$PLUGIN_DIR" \
  --description "E2E test plugin" \
  --author-name "Test User" \
  --author-email "test@example.com" \
  --skill-name e2e-skill \
  --skill-description "E2E test skill" \
  --register \
  --marketplace-dir "$MARKET_DIR")

echo "$OUTPUT" | jq .
```

Expected stdout JSON has all fields populated:
```json
{
  "dir": "/tmp/test-e2e-plugin-...",
  "name": "e2e-plugin",
  "plugin_json": "/tmp/test-e2e-plugin-.../.claude-plugin/plugin.json",
  "skill_created": "e2e-skill",
  "registered": true,
  "marketplace_name": "e2e-market",
  "marketplace_dir": "/tmp/test-e2e-market-..."
}
```

- [ ] **Step 2: Verify all created files**

```bash
echo "=== plugin.json ===" && cat "$PLUGIN_DIR/.claude-plugin/plugin.json"
echo "=== SKILL.md ===" && cat "$PLUGIN_DIR/skills/e2e-skill/SKILL.md"
echo "=== marketplace plugins ===" && jq '.plugins' "$MARKET_DIR/.claude-plugin/marketplace.json"
```

- [ ] **Step 3: Test --no-create adds a second skill to existing plugin**

```bash
bash /workspace/skills/plugin-init/scripts/init.sh \
  --name e2e-plugin \
  --dir "$PLUGIN_DIR" \
  --description "E2E test plugin" \
  --no-create \
  --skill-name second-skill | jq '.skill_created'
ls "$PLUGIN_DIR/skills/"
```

Expected: `"second-skill"`, both `e2e-skill/` and `second-skill/` listed.

- [ ] **Step 4: Commit**

```bash
git -C /workspace add skills/plugin-init/scripts/init.sh
git -C /workspace commit -m "test(plugin-init): verify end-to-end combined flow"
```

---

## Task 6: Write SKILL.md

**Files:**
- Modify: `skills/plugin-init/SKILL.md` (replace placeholder from Task 1)

- [ ] **Step 1: Write the full SKILL.md**

Replace `skills/plugin-init/SKILL.md` entirely with:

```markdown
---
name: plugin-init
description: Use when creating a new Claude Code plugin, scaffolding a plugin directory structure, initializing a new plugin with skills or agents, or setting up a plugin to distribute through a marketplace.
arguments: [name, dir, description, author-name, author-email, skill-name, skill-description]
argument-hint: [name] [dir] [description] [author-name] [author-email] [skill-name] [skill-description]
allowed-tools: Bash(bash *) Bash(claude *)
disable-model-invocation: true
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
```

- [ ] **Step 2: Verify SKILL.md frontmatter parses as valid YAML**

```bash
python3 -c "
content = open('/workspace/skills/plugin-init/SKILL.md').read()
fm = content.split('---')[1]
import yaml; yaml.safe_load(fm)
print('YAML OK')
"
```

Expected: `YAML OK`

- [ ] **Step 3: Commit**

```bash
git -C /workspace add skills/plugin-init/SKILL.md
git -C /workspace commit -m "feat(plugin-init): add SKILL.md with full conversation flow"
```

---

## Task 7: Final checks and integration commit

**Files:** No changes unless issues are found.

- [ ] **Step 1: Verify directory structure matches spec**

```bash
find /workspace/skills/plugin-init -type f | sort
```

Expected:
```
/workspace/skills/plugin-init/SKILL.md
/workspace/skills/plugin-init/scripts/init.sh
```

- [ ] **Step 2: Verify script has correct shebang and no syntax errors**

```bash
head -1 /workspace/skills/plugin-init/scripts/init.sh
bash -n /workspace/skills/plugin-init/scripts/init.sh && echo "syntax OK"
```

Expected: `#!/usr/bin/env bash`, then `syntax OK`.

- [ ] **Step 3: Verify no Windows line endings**

```bash
file /workspace/skills/plugin-init/scripts/init.sh
```

Expected: `ASCII text` or `Bourne-Again shell script` — not `CRLF`.

- [ ] **Step 4: Run full end-to-end with claude plugin validate (if available)**

```bash
PLUGIN_DIR=/tmp/final-e2e-plugin-$$
MARKET_DIR=/tmp/final-e2e-market-$$

bash /workspace/skills/marketplace-init/scripts/init.sh \
  --name final-market --dir "$MARKET_DIR" \
  --owner-name "Final Test" --description "Final test marketplace"

bash /workspace/skills/plugin-init/scripts/init.sh \
  --name final-plugin \
  --dir "$PLUGIN_DIR" \
  --description "Final test plugin" \
  --author-name "Final User" \
  --skill-name final-skill \
  --skill-description "Final skill" \
  --register \
  --marketplace-dir "$MARKET_DIR" | jq .

command -v claude >/dev/null 2>&1 \
  && claude plugin validate "$PLUGIN_DIR" \
  || echo "(claude CLI not available — skipping validate)"
```

- [ ] **Step 5: Final commit**

```bash
git -C /workspace add skills/plugin-init/
git -C /workspace commit -m "feat(plugin-init): complete skill — scaffold, skill placeholder, marketplace registration"
```
