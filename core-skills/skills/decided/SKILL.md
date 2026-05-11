---
name: decided
description: Use when the user wants to record a decision, add an ADR, capture why something was decided, mark an existing decision superseded or retired, or review active decisions. Triggers when choosing a framework, library, or major dependency; designing a data model; selecting an authentication strategy; deciding on API architecture; choosing infrastructure or tooling; or facing any decision that would be expensive to reverse.
---

# Decision Documenter

Creates, supersedes, retires, or reviews decision files in an ADR directory using frontmatter-backed markdown.

## Quick reference

| User intent | Workflow |
|-------------|----------|
| Record a new decision | [new decision](#workflow-new-decision) |
| Replace an existing decision | [supersede](#workflow-supersede-existing-decision) |
| Decision no longer relevant, not replaced | [retire](#workflow-retire-a-decision) |
| Proposal explicitly turned down | [reject](#workflow-reject-a-proposed-decision) |
| List what's currently decided | [review active](#workflow-review-active-decisions) |

## When NOT to use

- Reversible config changes (feature flags, env vars) — just change the value
- Purely operational decisions with no architectural consequence
- Decisions already self-documenting in code (naming, structure)
- Anything you'd undo in under an hour without hesitation

## Step 0: Locate ADR Directory

**Step 0a — Check current context first**

If your current context already contains an ADR directory path (from `CLAUDE.md`, `AGENTS.md`, or earlier in this conversation), set `<ADR_DIR>` to that path and proceed to Step 0c (skip Step 0b).

**Step 0b — Config absent: probe filesystem**

```bash
[ -d docs/decisions ] && echo exists || echo missing
```

If `docs/decisions/` **exists**, set `<ADR_DIR>` = `docs/decisions/` and go to Step 0c.

If **missing**, ask the user:

> No decisions directory found. Where should ADRs go?
> 1. Create `docs/decisions/` now
> 2. Specify a path
> 3. Other

| Choice | Action |
|--------|--------|
| **1 — Create** | `mkdir -p docs/decisions` then set `<ADR_DIR>` = `docs/decisions/` |
| **2 — Specify path** | Ask for the path; `[ -d <path> ]`; if missing ask to create; set `<ADR_DIR>` |
| **3 — Other** | Ask the user to describe what they want; adapt accordingly |

**Step 0c — Persist to project config**

Once `<ADR_DIR>` is resolved, record it so future sessions skip this discovery:

1. Prefer `CLAUDE.md`; fall back to `AGENTS.md`; if neither exists, create `CLAUDE.md`.
2. If `## ADR Directory` does not already exist in the target file:
   - Append:
      ```markdown
      ## ADR Directory

      ADRs are stored in `<ADR_DIR>`.
      ```
   - Inform the user: "Added ADR directory `<ADR_DIR>` to `CLAUDE.md`" (or whichever file was used).

Store the resolved path as `<ADR_DIR>` and substitute it everywhere in the workflows below.

## Templates

Ask the user which format they want — or suggest based on complexity:
- **Simple** — clear decision, low complexity, few/no alternatives
- **Full** — multiple options weighed, significant consequences, worth capturing the full reasoning trail

### Simple

```markdown
---
type: decision
id: "0042"
title: "Short decision title"
status: proposed
date: YYYY-MM-DD
superseded_by: ""
---

## Context
What situation or constraint led to this?

## Decision
**One sentence. Bold. What was decided.**

## Consequences
What becomes easier or harder. **Re-evaluate if:** [condition].

## Invariants
Load-bearing constraints any superseding decision must explicitly address — either preserve or consciously override with justification.
```

### Full

```markdown
---
type: decision
id: "0042"
title: "Short decision title"
status: proposed
date: YYYY-MM-DD
superseded_by: ""
responsible: ""   # does the work
accountable: ""   # owns the outcome, final sign-off
consulted: ""     # two-way input sought
informed: ""      # one-way, kept in the loop
---

## Context
What situation or constraint led to this? What problem is it solving?

## Decision drivers
- [force, constraint, or desired quality]
- [another driver]

## Decision
**Chosen: "[Option A]", because [one-sentence justification].**

## Options considered

### Option A (chosen)
- Good: …
- Bad: …

### Option B
- Good: …
- Bad: why rejected

## Consequences
What becomes easier or harder. **Re-evaluate if:** [condition].

## Confirmation
How to verify this decision is being followed — automated checks, code review criteria, fitness functions, or architectural tests. Omit if not applicable.

## Invariants
Load-bearing constraints any superseding decision must explicitly address — either preserve or consciously override with justification.
```

## Directory layout

- Each decision: `<ADR_DIR>/NNNN-kebab-title.md`
- Index: `<ADR_DIR>/index.md` — updated on every write

## Workflow: new decision

1. Ask simple or full.

2. Find next ID:
   ```bash
   ls <ADR_DIR>/[0-9]*.md 2>/dev/null | sort | tail -1
   ```
   Increment the highest number. Start at `0001` if none exist.

3. Interview the user — one section at a time, don't front-load:

   **Simple:** Context → Decision → Consequences + re-evaluate trigger → Invariants → Status (proposed or active?)

   **Full:** RACI (R/A/C/I — omit any that don't apply) → Context → Decision drivers → Options (ask for each alternative and its pros/cons) → Decision (chosen + justification) → Consequences + re-evaluate trigger → Confirmation (how will compliance be verified?) → Invariants → Status (proposed or active?)

4. Generate slug: kebab-case from the title, 3–5 words.

5. Write `<ADR_DIR>/NNNN-slug.md`.

6. Update `<ADR_DIR>/index.md`.

7. **Self-validate** — re-read both files and assert:
   - Required fields present: `type`, `id`, `title`, `status`, `date`
   - `status` is one of `proposed`, `rejected`, `active`, `superseded`, `retired`
   - If `status: superseded`, `superseded_by` is a non-empty `[[wikilink]]`
   - Decision file appears in `<ADR_DIR>/index.md`
   - No other decision file shares the same `id`

   If any assertion fails, fix immediately before reporting completion.

8. **Postprocess** — runs automatically after self-validate passes. No user interaction. Three sub-steps in sequence.

   **8a. Track touched files**

   Note which files were written during this workflow invocation:
   - `<ADR_DIR>/NNNN-new-slug.md` — always
   - `<ADR_DIR>/index.md` — always
   - `<ADR_DIR>/MMMM-superseded-slug.md` — only if a supersession occurred in this same invocation

   **8b. Relationship analysis (Haiku subagent)**

   Build a condensed summary of all existing ADRs (excluding the new one):

   ```bash
   NEW_ADR="<ADR_DIR>/NNNN-new-slug.md"   # substitute actual path
   for f in <ADR_DIR>/[0-9]*.md; do
     [ "$f" = "$NEW_ADR" ] && continue
     id=$(rg -m1 "^id:" "$f" | sed 's/^id: *//' | tr -d '"')
     title=$(rg -m1 "^title:" "$f" | sed 's/^title: *//' | tr -d '"')
     status=$(rg -m1 "^status:" "$f" | sed 's/^status: *//')
     decision=$(rg -m1 '^\*\*' "$f" | head -c 200)
     echo "$id | $title | $status | $decision"
   done
   ```

   Dispatch via the Agent tool:

   ```
   Agent(
     model: "haiku",
     subagent_type: "general-purpose",
     prompt: "You are auditing a new Architectural Decision Record (ADR) for
   relationships to existing ADRs in the same vault.

   NEW ADR (full content):
   [paste full new ADR markdown]

   EXISTING ADRs (condensed — id | title | status | decision summary):
   [paste output of bash script above]

   Identify meaningful relationships between the new ADR and existing ones.

   Relationship types:
     supersedes  — new ADR explicitly replaces this one
     extends     — new ADR builds on or specialises this one without replacing it
     related-to  — shared concern or relevant connection, no dependency
     contradicts — potential conflict worth flagging

   Return ONLY one of these two formats:

   Format A (relationships found):
   REFERENCES:
   - [[NNNN-slug]] — <type>: <one-clause reason>

   Format B (none found):
   NONE

   Rules:
   - Only include relationships that are meaningful and non-trivial
   - Maximum 6 references; prefer quality over completeness
   - Do not include a reference just because two ADRs touch the same system
   - supersedes is rare — only use if the new ADR directly replaces the old one's decision"
   )
   ```

   Handle the result:

   - **REFERENCES block returned:** parse entries, group by type — omit groups with no entries:
     - `supersedes` → `Supersedes:`
     - `extends` → `Extends (does not supersede):`
     - `related-to` → `Related:`
     - `contradicts` → `Contradicts:`

     Append `## References` section to the new ADR after `## Invariants`:

     ```markdown
     ## References

     Supersedes:
     - [[NNNN-slug]] — reason

     Related:
     - [[NNNN-slug]] — reason
     ```

   - **NONE returned:** do not add a `## References` section.
   - **`supersedes` flagged but supersede workflow not invoked:** warn the user ("Note: Haiku flagged [[NNNN-slug]] as potentially superseded — verify and run supersede workflow if correct"). Do not auto-update the old ADR's status.

   **8c. Targeted lint**

   For each touched file, run the following checks. Fix any failure immediately before reporting completion — same contract as step 7.

   **For each touched decision file (`NNNN-*.md`):**

   ```bash
   FILE="<ADR_DIR>/NNNN-slug.md"   # substitute actual path

   # Check 1: required fields present
   for field in type id title status date; do
     rg -q "^${field}:" "$FILE" || echo "FAIL check 1: missing field '$field' in $FILE"
   done

   # Check 2: valid status value
   status=$(rg -m1 "^status:" "$FILE" | sed 's/^status: *//')
   echo "$status" | rg -q "^(proposed|rejected|active|superseded|retired)$" \
     || echo "FAIL check 2: invalid status '$status' in $FILE"

   # Check 3: if superseded, superseded_by must be non-empty wikilink
   if [ "$status" = "superseded" ]; then
     sb=$(rg -m1 "^superseded_by:" "$FILE" | sed 's/^superseded_by: *//' | tr -d '"')
     [ -z "$sb" ] \
       && echo "FAIL check 3: status is superseded but superseded_by is empty in $FILE"

     # Check 4: wikilink target resolves
     target=$(echo "$sb" | sed 's/\[\[//;s/\]\]//')
     [ -f "<ADR_DIR>/${target}.md" ] \
       || echo "FAIL check 4: superseded_by target not found: <ADR_DIR>/${target}.md"
   fi

   # Check 5: id is unique across all decision files
   id=$(rg -m1 "^id:" "$FILE" | sed 's/^id: *//' | tr -d '"')
   count=$(rg -l "^id: \"${id}\"" <ADR_DIR>/[0-9]*.md | wc -l | tr -d ' ')
   [ "$count" -gt 1 ] \
     && echo "FAIL check 5: id '$id' appears in $count files"
   ```

   **For `<ADR_DIR>/index.md`:**

   ```bash
   BASENAME=$(basename "$FILE")

   # Check 6: touched decision file appears in index
   rg -q "$BASENAME" <ADR_DIR>/index.md \
     || echo "FAIL check 6: $BASENAME not found in <ADR_DIR>/index.md"

   # Check 7: index markdown link for this file points to existing file
   rg "\($BASENAME\)" <ADR_DIR>/index.md | rg -q . \
     || echo "FAIL check 7: no markdown link for $BASENAME in index"
   ```

## Workflow: supersede existing decision

1. Ask which decision is being superseded (ID or title). Read the file.
2. Update its frontmatter: `status: superseded`, `superseded_by: "[[NNNN-replacement-slug]]"`.
3. Run new decision workflow for the replacement. The new file's Context should note what it replaces and why.
4. Update the superseded file's row in the index to reflect `superseded → [[NNNN-new-slug|NNNN]]`.
5. **Self-validate** — re-read the superseded file and assert `status: superseded` and `superseded_by` resolves to the new file. Fix before reporting completion.

## Workflow: retire a decision

When the situation a decision addressed no longer exists (not replaced — just gone):

1. Update frontmatter: `status: retired`. Leave `superseded_by` empty.
2. Update the index.

## Workflow: reject a proposed decision

When a `proposed` decision is explicitly declined (not abandoned — consciously turned down):

1. Update frontmatter: `status: rejected`.
2. Update the index.
3. Leave the file intact. The rejected proposal captures what was considered and why — that context is valuable.

## Workflow: review active decisions

1. Read `<ADR_DIR>/index.md`.
2. Filter rows where `status` is `active`.
3. Present as a table. Flag rows with an old `date` as potentially stale. To check re-evaluate triggers, read the individual ADR files — that condition lives in the body, not the index.

## ADR lifecycle

```
proposed → active    → superseded | retired
         ↘ rejected
```

- `proposed` — drafted, not yet committed; still open for discussion or sign-off
- `rejected` — proposal explicitly declined; file kept for historical context
- `active` — operative; this is the current answer
- `superseded` — replaced by a newer decision (`superseded_by` points to it)
- `retired` — the situation it addressed no longer exists; not replaced

**Never delete old decisions.** When a decision changes, write a new ADR that supersedes the old one — don't edit or remove the original.

## Index format

```markdown
---
type: index
---

# Decisions

| ID | Title | Status |
|----|-------|--------|
| [0001](0001-slug.md) | Title here | proposed |
| [0002](0002-slug.md) | Title here | rejected |
| [0003](0003-slug.md) | Title here | active |
| [0004](0004-slug.md) | Title here | superseded → [[0007-slug\|0007]] |
| [0005](0005-slug.md) | Title here | retired |
```

Sorted by ID ascending.

## Invariants explained

The Invariants section captures load-bearing constraints that must survive supersession. A superseding decision doesn't need to keep them — but must consciously address each one and justify any change. This prevents silent regression without preventing deliberate evolution.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| `superseded_by` written as a path, not a wikilink | Use `[[NNNN-slug]]` — no file extension, double brackets |
| Forgetting index update on retire or reject | Index update required for all status changes, not just new decisions |
| Editing an active ADR in-place instead of superseding | Active ADRs are immutable; create a new ADR and supersede the old one |
| Non-zero-padded ID (e.g. `"42"` not `"0042"`) | IDs must be 4-digit zero-padded; sort order and lint check 5 depend on it |

## Markdown rendering: angle brackets in bold spans

Linked-note renderers (Obsidian, Foam, etc.) parse bare `<placeholder>` inside `**bold**` spans as HTML tags, breaking header rendering mid-document.

**Rule:** Never write `**... <foo> ...**`. Use backtick code spans for placeholders inside bold text:

```
# Bad — breaks rendering
**Save to raw/processed-<slug>.md.**

# Good — angle brackets literal inside backticks
**Save to `raw/processed-<slug>.md`.**
```

Placeholders outside bold text are fine as-is.
