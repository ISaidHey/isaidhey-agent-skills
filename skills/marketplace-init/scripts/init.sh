#!/usr/bin/env bash
set -euo pipefail

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

need_arg() { [[ $# -ge 2 ]] || { echo "Error: $1 requires a value" >&2; usage; }; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)        need_arg "$@"; OPT_NAME="$2";        shift 2 ;;
    --dir)         need_arg "$@"; OPT_DIR="$2";         shift 2 ;;
    --owner-name)  need_arg "$@"; OPT_OWNER_NAME="$2";  shift 2 ;;
    --owner-email) need_arg "$@"; OPT_OWNER_EMAIL="$2"; shift 2 ;;
    --description) need_arg "$@"; OPT_DESCRIPTION="$2"; shift 2 ;;
    -h|--help)     usage ;;
    *)             echo "Unknown option: $1" >&2; usage ;;
  esac
done

is_reserved() {
  local n="$1"
  for r in "${RESERVED_NAMES[@]}"; do
    [[ "$n" == "$r" ]] && return 0
  done
  return 1
}

# --- name ---
NAME="$OPT_NAME"
while true; do
  if [[ -z "$NAME" ]]; then
    read -rp "Marketplace name: " NAME || { echo "Cancelled." >&2; exit 1; }
  fi
  if [[ ! "$NAME" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
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
          if [[ "${confirm:-Y}" =~ ^[Yy]$ ]]; then
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

# --- resolve and validate target dir ---
DIR="$(realpath --canonicalize-missing -- "$DIR")"

# --- pre-write check ---
MARKETPLACE_FILE="$DIR/.claude-plugin/marketplace.json"
if [[ -f "$MARKETPLACE_FILE" ]]; then
  echo "Error: marketplace already exists at $MARKETPLACE_FILE" >&2
  exit 1
fi

# --- create dirs ---
mkdir -p "$DIR/.claude-plugin"

# --- write JSON ---
if [[ -n "$OWNER_EMAIL" ]]; then
  jq -n \
    --arg schema "$SCHEMA_URL" \
    --arg name   "$NAME" \
    --arg desc   "$DESCRIPTION" \
    --arg oname  "$OWNER_NAME" \
    --arg oemail "$OWNER_EMAIL" \
    '{
      "$schema":     $schema,
      "name":        $name,
      "description": $desc,
      "version":     "1.0.0",
      "owner":       {"name": $oname, "email": $oemail},
      "plugins":     []
    }' > "$MARKETPLACE_FILE"
else
  jq -n \
    --arg schema "$SCHEMA_URL" \
    --arg name   "$NAME" \
    --arg desc   "$DESCRIPTION" \
    --arg oname  "$OWNER_NAME" \
    '{
      "$schema":     $schema,
      "name":        $name,
      "description": $desc,
      "version":     "1.0.0",
      "owner":       {"name": $oname},
      "plugins":     []
    }' > "$MARKETPLACE_FILE"
fi

# --- output result to stdout ---
jq -n --arg dir "$DIR" --arg name "$NAME" --arg path "$MARKETPLACE_FILE" \
  '{"dir": $dir, "name": $name, "path": $path}'
