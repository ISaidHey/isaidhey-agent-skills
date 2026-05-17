---
name: llm-wiki-init
description: Initializes an llm-wiki vault. Run once in an empty directory after installing the llm-wiki-init plugin.
disable-model-invocation: true
---

# Skill: llm-wiki-init

One-time initialization wizard. Explains the system, collects configuration, copies template files, and scaffolds the vault. Run from inside the directory where the vault will live.

**Use the `AskUserQuestion` tool for every question in this skill.** Never ask questions as plain text output.

---

## Early Checks

Run all three before asking any questions. Fail fast.

### 1. Discover SKILL_DIR

```bash
find ~/.claude/plugins .claude/plugins -name "SKILL.md" -path "*/llm-wiki-init/skills/*" 2>/dev/null | xargs dirname | head -1
```

Store result as `SKILL_DIR`. If empty: stop and tell the user:

> "Could not locate the llm-wiki-init plugin installation directory. Make sure the `llm-wiki-init` plugin is installed and try again."

### 2. Already-initialized check

```bash
rg "\{\{VAULT_NAME\}\}" CLAUDE.md 2>/dev/null | head -1
```

If output is **empty** — the literal placeholder `{{VAULT_NAME}}` is no longer present — setup has already run. Tell the user and stop.

### 3. CWD conflict check

```bash
ls -A .
```

If the directory is non-empty: list the files and ask:

> "This directory is not empty. Copying template files may overwrite existing content. Continue? (yes / no)"

Do not proceed until the user confirms with "yes".

---

## Step 1 — What is this?

Output verbatim:

---

**Welcome.**

This is an llm-wiki — a self-building knowledge base.

- **You** drop sources into a folder — PDFs, articles, meeting notes, transcripts, web pages, anything you want to know about.
- **Claude** reads them, extracts what matters, and maintains a wiki — entities, concepts, cross-references, and citations.

You never do the bookkeeping. You add a source; Claude files the knowledge.

The wiki grows over time. A question asked six months from now draws on everything you've ever added. Every claim is traceable back to the exact source text that generated it.

The reasoning behind how this system is built is documented in `wiki/decisions/` — 12 founding decision records. 

You don't need to read them to start, but they explain the *why* behind how things work. A good starting point: `0001-operational-framework-code.md` and `0003-authorship-boundary-source-ingestion.md`.

---

## Step 2 — The four operations

Output verbatim:

---

Everything you do with this vault is one of four operations:

**Capture** — append a line to `capture.md`. One line, no processing needed.
```
- [2026-05-13] Article about climate data — https://example.com/article
- [2026-05-13] Q2 strategy deck — raw/q2-strategy.pdf
```

**Ingest** — say "ingest" to Claude. Claude reads the source, extracts knowledge, and updates 10–15 wiki pages. It strikes through the `capture.md` entry when done.

**Query** — ask Claude a question. It searches the wiki and synthesizes a cited answer. Good answers get filed as new wiki pages.

**Lint / Map** — periodic health checks. Lint finds broken links, orphaned pages, and missing citations. Map discovers patterns and implicit connections.

You'll use Capture and Ingest most. Query is where the value compounds.

---

## Step 3 — Configuration

Output verbatim:

---

"Sources" are the files you drop for Claude to read — PDFs, articles, exported notes, transcripts. Where you store them is up to you.

This vault also uses **workstreams** — named knowledge domains that keep content organized as the wiki grows. Concept and entity pages live in workstream-namespaced subdirectories, enabling filtered queries and preventing context bleed between domains.

---

Use `AskUserQuestion` with **three questions in a single call**:

1. header `Source layout`, question "How do you want to organize source files?", options:
   - `Flat (raw/)` — single drop zone
   - `PARA` — projects / areas / resources / archives
   - `Domain folders` — your own named folders inside raw/
   - `Custom` — describe your own layout

2. header `Workstreams`, question "What knowledge areas will this vault cover? (comma-separated — these become workstream identifiers)", options:
   - `work, research, personal`
   - `work, hobbies`
   - `research, notes`

3. header `Vault name`, question "What do you want to call this vault?", options:
   - `My Wiki`
   - `Knowledge Base`
   - `Research Notes`

Store results: `SOURCE_STRUCTURE` (`raw`/`para`/`domain`/`custom`), `WORKSTREAM_NAMES` (split on commas, trim), `VAULT_NAME`. `SOURCE_DIR = "raw/"` for all structures.

If workstreams response is empty or non-committal ("none", "idk", "skip", etc.): use `WORKSTREAM_NAMES = ["default"]`. Tell user: "Using `default` as your workstream. You can rename it later."

**Follow-up questions (only if needed):**
- If **domain**: one more `AskUserQuestion` — header `Domain names`, question "What domain names? (comma-separated)", options `work, hobbies` / `work, research, personal` / `projects, reference`. Split on commas, trim, store as `DOMAIN_NAMES`.
- If **custom**: ask as plain text: "Describe your structure." Store as `CUSTOM_DESCRIPTION`. `SOURCE_DIR` = first directory mentioned.

## Step 4 — Preview

Show the vault structure that will be created. Substitute actual workstream and domain names.

**`raw/` structure:**
```
<vault-root>/
  CLAUDE.md
  Start Here.md
  capture.md
  raw/
  wiki/
    index.md
    log.md
    decisions/        (12 ADRs)
    concepts/
      <workstream>/   ← one per workstream
    entities/
      <workstream>/   ← one per workstream
  .claude/
    rules/
```

**PARA** — replace `raw/` with:
```
  raw/
    projects/
    areas/
    resources/
    archives/
```

**Domain dirs** (e.g. `work, hobbies`) — replace `raw/` with:
```
  raw/
    work/
    hobbies/
```

Ask: "Does this look right? Type yes to proceed, or describe any changes."

**Do not write any files until the user confirms.**

## Step 5 — Setup

Run `setup.sh` from the vault root. It copies the template, substitutes all placeholders, creates source and workstream directories, and logs the run — one call.

```bash
bash "$SKILL_DIR/scripts/setup.sh" \
  --skill-dir "$SKILL_DIR" \
  --vault-name "$VAULT_NAME" \
  --source-structure "$SOURCE_STRUCTURE" \
  --workstream-names "$WORKSTREAM_NAMES_CSV"
```

Add `--domain-names "$DOMAIN_NAMES_CSV"` when `SOURCE_STRUCTURE=domain`.

For `custom` with a non-standard layout, add overrides:
```
  --structure-block "..."   # tree block for CLAUDE.md vault structure section
  --source-dir "raw/..."    # default drop dir shown in Start Here.md
  --source-dir-desc "raw/"  # prose description
  --source-tree "raw/..."   # compact tree line
```

`$WORKSTREAM_NAMES_CSV` and `$DOMAIN_NAMES_CSV` are the collected names joined by `, `.

## Step 6 — Verify

### Placeholder scan

```bash
rg "\{\{[A-Z_]+\}\}" .
```

Zero hits = success. Any hit: report exact file:line and tell the user which substitution failed. Offer to fix it.

Also check that Start Here.md has no unsubstituted bracket placeholders:

```bash
rg "\[SOURCE_DIR\]|\[SOURCE_TREE\]|\[SOURCE_DIR_DESCRIPTION\]" "Start Here.md"
```

Zero hits = success. Any hit means 8b substitution failed.

### Log entry check

```bash
rg "setup" wiki/log.md | tail -1
```

Expected: the setup entry appended in 8e.

### Workstream dirs check

For each name in `WORKSTREAM_NAMES`, verify:

```bash
ls "wiki/concepts/$name" "wiki/entities/$name"
```

Expected: `.gitkeep` in each. If missing: re-run step 8d for that workstream.

If all checks pass, proceed to Step 7.

## Step 7 — What's next

Tell the user:

(Substitute `[SOURCE_DIR]` with the actual `SOURCE_DIR` value collected in Step 3.)

---

**Your vault is ready.**

To add knowledge:

1. Drop a source file into `[SOURCE_DIR]`
2. Append a line to `capture.md`:
   ```
   - [YYYY-MM-DD] What it is — path/or/url
   ```
3. Say **"ingest"**

To query the wiki, just ask a question.

Your workstreams: **[list WORKSTREAM_NAMES joined by ", "]**. If WORKSTREAM_NAMES has more than one entry: add "When you ingest a source, tell Claude which workstream it belongs to."

Reference: `Start Here.md` for day-to-day usage. `wiki/decisions/` for the reasoning behind how this system works.

---

Then run:

```bash
claude plugin install wiki-mgmt@isaidhey-agent-skills --scope project
```

Do not tell the user to run this — execute it directly.
