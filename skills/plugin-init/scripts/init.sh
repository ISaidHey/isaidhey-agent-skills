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
DIR="$(realpath --canonicalize-missing -- "$OPT_DIR")" || { echo "Error: cannot resolve path: $OPT_DIR" >&2; exit 1; }

# Result variables — written by functions, assembled into JSON at end
RESULT_NAME="$OPT_NAME"
RESULT_DIR="$DIR"
RESULT_PLUGIN_JSON="$DIR/.claude-plugin/plugin.json"
RESULT_SKILL_CREATED=""
RESULT_REGISTERED=false
RESULT_MARKETPLACE_NAME=""
RESULT_MARKETPLACE_DIR_OUT=""

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
