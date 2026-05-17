#!/usr/bin/env bash
# Full vault setup: copy template, substitute placeholders, scaffold dirs, log.
# Usage: setup.sh --skill-dir DIR --vault-name NAME --source-structure STR
#                 --workstream-names CSV [--domain-names CSV]
#                 [--structure-block STR] [--source-dir DIR]
#                 [--source-dir-desc STR] [--source-tree STR]
set -euo pipefail

SKILL_DIR=""
VAULT_NAME=""
SOURCE_STRUCTURE=""
WORKSTREAM_NAMES=""
DOMAIN_NAMES=""
OPT_STRUCTURE_BLOCK=""
OPT_SOURCE_DIR=""
OPT_SOURCE_DIR_DESC=""
OPT_SOURCE_TREE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill-dir)        SKILL_DIR="$2";             shift 2 ;;
    --vault-name)       VAULT_NAME="$2";            shift 2 ;;
    --source-structure) SOURCE_STRUCTURE="$2";      shift 2 ;;
    --workstream-names) WORKSTREAM_NAMES="$2";      shift 2 ;;
    --domain-names)     DOMAIN_NAMES="$2";          shift 2 ;;
    --structure-block)  OPT_STRUCTURE_BLOCK="$2";   shift 2 ;;
    --source-dir)       OPT_SOURCE_DIR="$2";        shift 2 ;;
    --source-dir-desc)  OPT_SOURCE_DIR_DESC="$2";   shift 2 ;;
    --source-tree)      OPT_SOURCE_TREE="$2";       shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$SKILL_DIR" ]]        || { echo "Missing --skill-dir" >&2;        exit 1; }
[[ -n "$VAULT_NAME" ]]       || { echo "Missing --vault-name" >&2;       exit 1; }
[[ -n "$SOURCE_STRUCTURE" ]] || { echo "Missing --source-structure" >&2; exit 1; }
[[ -n "$WORKSTREAM_NAMES" ]] || { echo "Missing --workstream-names" >&2; exit 1; }

# --- Copy template ---
cp -r "$SKILL_DIR/src/." .

# --- Derive structure-specific values ---
case "$SOURCE_STRUCTURE" in
  raw)
    STRUCTURE_BLOCK='  raw/            ← source files: drop PDFs, docs, exports, transcripts here'
    SOURCE_DIR="raw/"
    SOURCE_DIR_DESC="raw/"
    SOURCE_TREE="raw/         ← source files"
    ;;
  para)
    STRUCTURE_BLOCK='  raw/
    projects/     ← source files: active work
    areas/        ← source files: ongoing responsibilities
    resources/    ← source files: reference material
    archives/     ← source files: inactive'
    SOURCE_DIR="raw/"
    SOURCE_DIR_DESC="raw/"
    SOURCE_TREE="raw/projects/, raw/areas/, raw/resources/, raw/archives/"
    ;;
  domain)
    [[ -n "$DOMAIN_NAMES" ]] || { echo "domain structure requires --domain-names" >&2; exit 1; }
    IFS=',' read -ra DOMAINS <<< "$DOMAIN_NAMES"
    STRUCTURE_BLOCK="  raw/"
    SOURCE_TREE=""
    for domain in "${DOMAINS[@]}"; do
      domain="${domain// /}"
      STRUCTURE_BLOCK+=$'\n'"    ${domain}/   ← source files: ${domain}-related"
      SOURCE_TREE+="raw/${domain}/, "
    done
    SOURCE_TREE="${SOURCE_TREE%, }"
    FIRST_DOMAIN="${DOMAINS[0]// /}"
    SOURCE_DIR="raw/${FIRST_DOMAIN}/"
    SOURCE_DIR_DESC="raw/"
    ;;
  custom)
    STRUCTURE_BLOCK="  raw/            ← source files"
    SOURCE_DIR="raw/"
    SOURCE_DIR_DESC="raw/"
    SOURCE_TREE="raw/"
    ;;
  *)
    echo "Unknown source structure: $SOURCE_STRUCTURE" >&2; exit 1 ;;
esac

[[ -n "$OPT_STRUCTURE_BLOCK" ]] && STRUCTURE_BLOCK="$OPT_STRUCTURE_BLOCK"
[[ -n "$OPT_SOURCE_DIR" ]]      && SOURCE_DIR="$OPT_SOURCE_DIR"
[[ -n "$OPT_SOURCE_DIR_DESC" ]] && SOURCE_DIR_DESC="$OPT_SOURCE_DIR_DESC"
[[ -n "$OPT_SOURCE_TREE" ]]     && SOURCE_TREE="$OPT_SOURCE_TREE"

# --- Substitute placeholders ---
VAULT_NAME="$VAULT_NAME" \
CREATED_DATE="$(date +%Y-%m-%d)" \
STRUCTURE_BLOCK="$STRUCTURE_BLOCK" \
  perl -i -0777 -pe '
    s/\{\{VAULT_NAME\}\}/$ENV{VAULT_NAME}/g;
    s/\{\{CREATED_DATE\}\}/$ENV{CREATED_DATE}/g;
    s/\{\{SOURCE_STRUCTURE_BLOCK\}\}/$ENV{STRUCTURE_BLOCK}/g;
  ' CLAUDE.md

SOURCE_DIR="$SOURCE_DIR" \
SOURCE_DIR_DESC="$SOURCE_DIR_DESC" \
SOURCE_TREE="$SOURCE_TREE" \
  perl -i -0777 -pe '
    s/\[SOURCE_DIR_DESCRIPTION\]/$ENV{SOURCE_DIR_DESC}/g;
    s/\[SOURCE_TREE\]/$ENV{SOURCE_TREE}/g;
    s/\[SOURCE_DIR\]/$ENV{SOURCE_DIR}/g;
  ' "Start Here.md"

# --- Source directories ---
case "$SOURCE_STRUCTURE" in
  raw|custom)
    mkdir -p raw && touch raw/.gitkeep
    ;;
  para)
    mkdir -p raw/projects raw/areas raw/resources raw/archives
    for d in raw/projects raw/areas raw/resources raw/archives; do
      touch "$d/.gitkeep"
    done
    ;;
  domain)
    IFS=',' read -ra DOMAINS <<< "$DOMAIN_NAMES"
    for domain in "${DOMAINS[@]}"; do
      domain="${domain// /}"
      mkdir -p "raw/$domain" && touch "raw/$domain/.gitkeep"
    done
    ;;
esac

# --- Workstream subdirectories ---
IFS=',' read -ra WORKSTREAMS <<< "$WORKSTREAM_NAMES"
for name in "${WORKSTREAMS[@]}"; do
  name="${name// /}"
  mkdir -p "wiki/concepts/$name" "wiki/entities/$name"
  touch "wiki/concepts/$name/.gitkeep" "wiki/entities/$name/.gitkeep"
done
rm -f wiki/concepts/.gitkeep wiki/entities/.gitkeep

# --- Log ---
printf "\n## [%s] setup | %s — source: %s | workstreams: %s\n" \
  "$(date +%Y-%m-%d)" "$VAULT_NAME" "$SOURCE_STRUCTURE" "$WORKSTREAM_NAMES" \
  >> wiki/log.md
