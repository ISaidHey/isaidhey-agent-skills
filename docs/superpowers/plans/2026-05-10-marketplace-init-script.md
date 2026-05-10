# marketplace-init Script Delegation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the marketplace-init skill's inline wizard with a bash script that handles all prompting, validation, and file creation, leaving the skill as a thin shim that calls the script and renders next steps.

**Architecture:** A new `skills/marketplace-init/scripts/init.sh` script accepts named flags, interactively prompts for any missing values, validates input, and writes `marketplace.json`. The updated `SKILL.md` calls the script (forwarding any pre-supplied args as flags), then parses the JSON stdout to render the next-steps block.

**Tech Stack:** Bash, Claude Code skill SKILL.md format

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `skills/marketplace-init/scripts/init.sh` | All prompting, validation, file creation, JSON stdout |
| Modify | `skills/marketplace-init/SKILL.md` | Thin shim: call script, render next steps |

---

### Task 1: Script skeleton with flag parsing

**Files:**
- Create: `skills/marketplace-init/scripts/init.sh`

- [ ] **Step 1: Create the script file with skeleton**

```bash
#!/usr/bin/env bash
set -uo pipefail

RESERVED_NAMES=(
  "claude-code-marketplace"
  "claude-code-plugins"
  "claude-plugins-official"
  "anthropic-marketplace"
  "anthropic-plugins"
  "agent-skills"
  "knowledge-work-plugins"
  "life-sciences"
)
SCHEMA_URL="https://json.schemastore.org/claude-code-marketplace.json"

OPT_NAME=""
OPT_DIR=""
OPT_OWNER_NAME=""
OPT_OWNER_EMAIL=""
OPT_DESCRIPTION=""

usage() {
  cat >&2 <<'EOF'
Usage: init.sh [OPTIONS]

Options:
  --name NAME            Marketplace name (kebab-case)
  --dir DIR              Target directory
  --owner-name NAME      Owner or team name
  --owner-email EMAIL    Owner email (optional)
  --description DESC     Marketplace description
  -h, --help             Show this help
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)        OPT_NAME="${2:-}";        shift 2 ;;
    --dir)         OPT_DIR="${2:-}";         shift 2 ;;
    --owner-name)  OPT_OWNER_NAME="${2:-}";  shift 2 ;;
    --owner-email) OPT_OWNER_EMAIL="${2:-}"; shift 2 ;;
    --description) OPT_DESCRIPTION="${2:-}"; shift 2 ;;
    -h|--help)     usage ;;
    *)             echo "Unknown option: $1" >&2; usage ;;
  esac
done

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

is_reserved() {
  local n="$1"
  for r in "${RESERVED_NAMES[@]}"; do
    [[ "$n" == "$r" ]] && return 0
  done
  return 1
}

echo "Marketplace init complete (stub)" >&2
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x skills/marketplace-init/scripts/init.sh
```

- [ ] **Step 3: Verify unknown flag errors correctly**

```bash
bash skills/marketplace-init/scripts/init.sh --bogus
```

Expected: prints `Unknown option: --bogus`, usage block, exits non-zero.

- [ ] **Step 4: Verify help flag works**

```bash
bash skills/marketplace-init/scripts/init.sh --help
```

Expected: prints usage block, exits non-zero.

- [ ] **Step 5: Commit**

```bash
git commit -am "feat: add marketplace-init script skeleton with flag parsing"
```

---

### Task 2: Name prompt and validation

**Files:**
- Modify: `skills/marketplace-init/scripts/init.sh`

- [ ] **Step 1: Replace the stub `echo` at the bottom with the name prompt block**

Remove:
```bash
echo "Marketplace init complete (stub)" >&2
```

Add:
```bash
# --- name ---
NAME="$OPT_NAME"
while true; do
  if [[ -z "$NAME" ]]; then
    read -rp "Marketplace name: " NAME || { echo "Cancelled." >&2; exit 1; }
  fi
  if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    echo "Invalid: must be lowercase letters, numbers, and hyphens only (e.g. acme-tools)" >&2
    NAME=""
    continue
  fi
  if is_reserved "$NAME"; then
    echo "Invalid: '$NAME' is a reserved name" >&2
    NAME=""
    continue
  fi
  break
done

echo "Name collected: $NAME" >&2
```

- [ ] **Step 2: Verify valid name accepted via flag (no prompt)**

```bash
bash skills/marketplace-init/scripts/init.sh --name acme-tools
```

Expected: prints `Name collected: acme-tools`, exits 0.

- [ ] **Step 3: Verify reserved name rejected via flag**

```bash
bash skills/marketplace-init/scripts/init.sh --name agent-skills
```

Expected: prints `Invalid: 'agent-skills' is a reserved name`, exits non-zero (no prompt since non-interactive).

Note: when `--name` is supplied and invalid, the loop clears `NAME` and loops again — but since `OPT_NAME` still holds the bad value, this creates an infinite loop. Fix by reading from `OPT_NAME` only on first pass. Update the validation loop:

```bash
NAME="$OPT_NAME"
while true; do
  if [[ -z "$NAME" ]]; then
    read -rp "Marketplace name: " NAME || { echo "Cancelled." >&2; exit 1; }
  fi
  if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    echo "Invalid: must be lowercase letters, numbers, and hyphens only (e.g. acme-tools)" >&2
    NAME=""
    OPT_NAME=""
    continue
  fi
  if is_reserved "$NAME"; then
    echo "Invalid: '$NAME' is a reserved name" >&2
    NAME=""
    OPT_NAME=""
    continue
  fi
  break
done
```

- [ ] **Step 4: Re-verify reserved name via flag now exits cleanly**

```bash
echo "" | bash skills/marketplace-init/scripts/init.sh --name agent-skills
```

Expected: error message, then Cancelled (EOF), exits 1.

- [ ] **Step 5: Remove the debug echo once validation confirmed**

Remove:
```bash
echo "Name collected: $NAME" >&2
```

- [ ] **Step 6: Commit**

```bash
git commit -am "feat: add name prompt and validation to init script"
```

---

### Task 3: Directory menu

**Files:**
- Modify: `skills/marketplace-init/scripts/init.sh`

- [ ] **Step 1: Add the directory menu block after the name block**

```bash
# --- dir ---
DIR="$OPT_DIR"
if [[ -z "$DIR" ]]; then
  while true; do
    if [[ -d "$NAME" ]]; then
      echo "Directory options:"
      echo "  1) Use ./$NAME"
      echo "  2) Enter a different directory"
      echo "  3) Cancel"
    else
      echo "Directory options:"
      echo "  1) Create ./$NAME"
      echo "  2) Enter a different directory"
      echo "  3) Cancel"
    fi
    read -rp "Enter your choice: " choice || { echo "Cancelled." >&2; exit 1; }
    case "$choice" in
      1)
        DIR="$NAME"
        break
        ;;
      2)
        read -rp "Directory path: " DIR || { echo "Cancelled." >&2; exit 1; }
        if [[ ! -d "$DIR" ]]; then
          read -rp "Directory does not exist. Create it? [Y/n] " confirm || confirm="Y"
          confirm="${confirm:-Y}"
          if [[ "$confirm" =~ ^[Yy]$ ]] || [[ -z "$confirm" ]]; then
            break
          else
            DIR=""
            continue
          fi
        else
          break
        fi
        ;;
      3)
        echo "Cancelled." >&2
        exit 1
        ;;
      *)
        echo "Invalid choice. Please enter 1, 2, or 3." >&2
        ;;
    esac
  done
fi

echo "Dir: $DIR" >&2
```

- [ ] **Step 2: Verify `--dir` flag skips menu entirely**

```bash
bash skills/marketplace-init/scripts/init.sh --name acme-tools --dir /tmp/test-market
```

Expected: skips dir menu, prints `Dir: /tmp/test-market`.

- [ ] **Step 3: Verify menu choice 1 when dir doesn't exist — shows "Create" variant**

```bash
echo "1" | bash skills/marketplace-init/scripts/init.sh --name acme-tools
```

Expected: shows `1) Create ./acme-tools`, accepts choice `1`, prints `Dir: acme-tools`.

- [ ] **Step 4: Verify choice 3 cancels**

```bash
echo "3" | bash skills/marketplace-init/scripts/init.sh --name acme-tools
```

Expected: prints `Cancelled.`, exits 1.

- [ ] **Step 5: Verify invalid choice re-prompts**

```bash
printf "9\n3\n" | bash skills/marketplace-init/scripts/init.sh --name acme-tools
```

Expected: `Invalid choice. Please enter 1, 2, or 3.` then re-shows menu, then `Cancelled.` on choice 3.

- [ ] **Step 6: Remove the debug echo**

Remove:
```bash
echo "Dir: $DIR" >&2
```

- [ ] **Step 7: Commit**

```bash
git commit -am "feat: add directory menu to init script"
```

---

### Task 4: Owner name, email, and description prompts

**Files:**
- Modify: `skills/marketplace-init/scripts/init.sh`

- [ ] **Step 1: Add remaining prompts after the dir block**

```bash
# --- owner name ---
OWNER_NAME="$OPT_OWNER_NAME"
while [[ -z "$OWNER_NAME" ]]; do
  read -rp "Owner name: " OWNER_NAME || { echo "Cancelled." >&2; exit 1; }
  [[ -z "$OWNER_NAME" ]] && echo "Owner name is required." >&2
done

# --- owner email ---
OWNER_EMAIL="$OPT_OWNER_EMAIL"
if [[ -z "$OWNER_EMAIL" ]]; then
  read -rp "Owner email (optional, press Enter to skip): " OWNER_EMAIL || OWNER_EMAIL=""
fi

# --- description ---
DESCRIPTION="$OPT_DESCRIPTION"
while [[ -z "$DESCRIPTION" ]]; do
  read -rp "Description: " DESCRIPTION || { echo "Cancelled." >&2; exit 1; }
  [[ -z "$DESCRIPTION" ]] && echo "Description is required." >&2
done

echo "owner=$OWNER_NAME email=$OWNER_EMAIL desc=$DESCRIPTION" >&2
```

- [ ] **Step 2: Verify all fields supplied via flags skips all prompts**

```bash
bash skills/marketplace-init/scripts/init.sh \
  --name acme-tools \
  --dir /tmp/test-market \
  --owner-name "Acme Corp" \
  --owner-email "ops@acme.com" \
  --description "Acme internal tools marketplace"
```

Expected: prints the debug line with all three values, exits 0.

- [ ] **Step 3: Verify blank owner name re-prompts**

```bash
printf "\nAcme Corp\nops@acme.com\nAcme internal tools\n" | \
  bash skills/marketplace-init/scripts/init.sh --name acme-tools --dir /tmp/x
```

Expected: `Owner name is required.` on blank input, then accepts `Acme Corp`.

- [ ] **Step 4: Remove the debug echo**

Remove:
```bash
echo "owner=$OWNER_NAME email=$OWNER_EMAIL desc=$DESCRIPTION" >&2
```

- [ ] **Step 5: Commit**

```bash
git commit -am "feat: add owner and description prompts to init script"
```

---

### Task 5: Pre-write check, file creation, and JSON output

**Files:**
- Modify: `skills/marketplace-init/scripts/init.sh`

- [ ] **Step 1: Add pre-write check, file creation, and JSON output after the prompts**

```bash
# --- pre-write check ---
MARKETPLACE_FILE="$DIR/.claude-plugin/marketplace.json"
if [[ -f "$MARKETPLACE_FILE" ]]; then
  echo "Error: marketplace already exists at $MARKETPLACE_FILE" >&2
  exit 1
fi

# --- create dirs ---
mkdir -p "$DIR/.claude-plugin"

# --- write JSON ---
NAME_ESC="$(json_escape "$NAME")"
DESC_ESC="$(json_escape "$DESCRIPTION")"
OWNER_NAME_ESC="$(json_escape "$OWNER_NAME")"

{
  printf '{\n'
  printf '  "$schema": "%s",\n' "$SCHEMA_URL"
  printf '  "name": "%s",\n' "$NAME_ESC"
  printf '  "description": "%s",\n' "$DESC_ESC"
  printf '  "version": "1.0.0",\n'
  printf '  "owner": {\n'
  if [[ -n "$OWNER_EMAIL" ]]; then
    OWNER_EMAIL_ESC="$(json_escape "$OWNER_EMAIL")"
    printf '    "name": "%s",\n' "$OWNER_NAME_ESC"
    printf '    "email": "%s"\n' "$OWNER_EMAIL_ESC"
  else
    printf '    "name": "%s"\n' "$OWNER_NAME_ESC"
  fi
  printf '  },\n'
  printf '  "plugins": []\n'
  printf '}\n'
} > "$MARKETPLACE_FILE"

# --- output result to stdout ---
DIR_ESC="$(json_escape "$DIR")"
PATH_ESC="$(json_escape "$MARKETPLACE_FILE")"
printf '{"dir":"%s","name":"%s","path":"%s"}\n' "$DIR_ESC" "$NAME_ESC" "$PATH_ESC"
```

- [ ] **Step 2: Run full end-to-end with all flags**

```bash
bash skills/marketplace-init/scripts/init.sh \
  --name acme-tools \
  --dir /tmp/test-market \
  --owner-name "Acme Corp" \
  --owner-email "ops@acme.com" \
  --description "Acme internal tools marketplace"
```

Expected stdout (single line):
```
{"dir":"/tmp/test-market","name":"acme-tools","path":"/tmp/test-market/.claude-plugin/marketplace.json"}
```

- [ ] **Step 3: Verify the generated JSON file**

```bash
cat /tmp/test-market/.claude-plugin/marketplace.json
```

Expected:
```json
{
  "$schema": "https://json.schemastore.org/claude-code-marketplace.json",
  "name": "acme-tools",
  "description": "Acme internal tools marketplace",
  "version": "1.0.0",
  "owner": {
    "name": "Acme Corp",
    "email": "ops@acme.com"
  },
  "plugins": []
}
```

- [ ] **Step 4: Verify email omitted when skipped**

```bash
rm -rf /tmp/test-market2
bash skills/marketplace-init/scripts/init.sh \
  --name acme-tools \
  --dir /tmp/test-market2 \
  --owner-name "Acme Corp" \
  --description "Acme internal tools marketplace"
cat /tmp/test-market2/.claude-plugin/marketplace.json
```

Expected: `owner` block has only `name`, no `email` key.

- [ ] **Step 5: Verify pre-write check blocks second run**

```bash
bash skills/marketplace-init/scripts/init.sh \
  --name acme-tools \
  --dir /tmp/test-market \
  --owner-name "Acme Corp" \
  --description "Acme internal tools marketplace"
```

Expected: `Error: marketplace already exists at /tmp/test-market/.claude-plugin/marketplace.json`, exits 1.

- [ ] **Step 6: Clean up temp dirs and commit**

```bash
rm -rf /tmp/test-market /tmp/test-market2
git commit -am "feat: add file creation and JSON output to init script"
```

---

### Task 6: Update SKILL.md to call script and render next steps

**Files:**
- Modify: `skills/marketplace-init/SKILL.md`

- [ ] **Step 1: Replace the entire SKILL.md content**

```markdown
---
name: marketplace-init
description: Set up a Claude Code plugin marketplace in a target directory. Use when creating a new marketplace, scaffolding marketplace structure, or initializing plugin distribution.
arguments: [dir, name]
argument-hint: <dir> [marketplace-name]
allowed-tools: Bash(bash *)
---

# Marketplace Init

## Run

Build the command: `bash skills/marketplace-init/scripts/init.sh`

- If `$name` is not empty, append `--name "$name"`
- If `$dir` is not empty, append `--dir "$dir"`

Run the command. The script handles all prompting interactively.

If the script exits with a non-zero status, stop. Do not render next steps.

## On success

The script writes a single JSON line to stdout. Parse it to extract `dir`, `name`, and `path`.

Display:

```
✓ Marketplace created at <path>

Next steps:
1. Validate:  claude plugin validate <dir>
2. Add:       /plugin marketplace add <dir>
3. Install:   /plugin install <plugin-name>@<name>

Version is set to "1.0.0". Bump it on each release, or remove it entirely
to track git commit SHA automatically (every commit = new version).

Add plugins to the plugins[] array in marketplace.json when ready.
```

Substitute `<path>`, `<dir>`, and `<name>` with the values from the JSON output.
```

- [ ] **Step 2: Verify the file was written correctly**

```bash
head -10 skills/marketplace-init/SKILL.md
```

Expected: frontmatter with `allowed-tools: Bash(bash *)` and no `disable-model-invocation`.

- [ ] **Step 3: Commit**

```bash
git commit -am "refactor: update SKILL.md to delegate to init.sh script"
```

---

### Task 7: End-to-end smoke test

- [ ] **Step 1: Run script interactively (fully manual — simulate user input)**

```bash
printf "my-test-market\n1\nTest User\ntest@example.com\nA test marketplace\n" | \
  bash skills/marketplace-init/scripts/init.sh
```

Expected stdout: JSON line with `my-test-market` as name and dir.

- [ ] **Step 2: Verify generated file**

```bash
cat my-test-market/.claude-plugin/marketplace.json
```

Expected: valid JSON with all fields populated, `"plugins": []`.

- [ ] **Step 3: Clean up**

```bash
rm -rf my-test-market
```

- [ ] **Step 4: Final commit (if any uncommitted changes)**

```bash
git status
```

If clean, no commit needed.
