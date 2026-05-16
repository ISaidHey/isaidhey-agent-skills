# Skill Authoring

How to write effective `SKILL.md` files after `/plugin-init` creates the placeholder.

## SKILL.md structure

```markdown
---
description: What this skill does and when Claude should use it. Put the key use case first.
disable-model-invocation: true
allowed-tools: Bash(git *)
---

Your instructions here.
```

Frontmatter is optional. Only `description` is strongly recommended.

## Frontmatter reference

| Field | Description |
|-------|-------------|
| `name` | Display name. Defaults to directory name. Lowercase, numbers, hyphens, max 64 chars. |
| `description` | What the skill does. Claude uses this to decide when to load it automatically. Truncated at 1,536 chars in skill listing — put the key use case first. |
| `when_to_use` | Extra trigger context appended to `description`. Counts toward the 1,536-char cap. |
| `argument-hint` | Shown in autocomplete. Example: `[issue-number]` or `[filename] [format]`. |
| `arguments` | Named positional args for `$name` substitution. Space-separated string or YAML list. |
| `disable-model-invocation` | `true` → only you can invoke it (not Claude). Use for workflows with side effects like deploy, commit, send-message. |
| `user-invocable` | `false` → only Claude invokes it (hidden from `/` menu). Use for background knowledge. |
| `allowed-tools` | Tools Claude can use without approval prompts when this skill is active. |
| `model` | Model override for this skill's turn. |
| `effort` | Effort level override: `low`, `medium`, `high`, `xhigh`, `max`. |
| `context` | `fork` → run in isolated subagent context. |
| `agent` | Which subagent to use when `context: fork` is set. |
| `hooks` | Hooks scoped to this skill's lifecycle. |
| `paths` | Glob patterns — auto-activate only when working on matching files. |

## Invocation control

| Frontmatter | You invoke | Claude invokes | In context |
|-------------|-----------|----------------|------------|
| (default) | Yes | Yes | Description always present |
| `disable-model-invocation: true` | Yes | No | Not in context until you invoke |
| `user-invocable: false` | No | Yes | Description always present |

## Arguments

`$ARGUMENTS` — everything after the skill name:
```yaml
---
name: fix-issue
---
Fix GitHub issue $ARGUMENTS following our coding standards.
```
`/fix-issue 123` → Claude sees "Fix GitHub issue 123..."

Positional access: `$ARGUMENTS[0]`, `$ARGUMENTS[1]`, or shorthand `$0`, `$1`.

Named args via frontmatter:
```yaml
---
arguments: [issue, branch]
---
Fix $issue on branch $branch.
```

## Dynamic context injection

`` !`command` `` runs before Claude sees the skill — output replaces the placeholder:

```yaml
---
name: pr-summary
allowed-tools: Bash(gh *)
---
## PR diff
!`gh pr diff`

## Comments
!`gh pr view --comments`

Summarize these changes.
```

Multi-line version:
````markdown
## Environment
```!
node --version
npm --version
git status --short
```
````

Use `${CLAUDE_SKILL_DIR}` to reference scripts bundled with the skill:
```bash
!`bash ${CLAUDE_SKILL_DIR}/scripts/gather-context.sh`
```

## Subagent execution

`context: fork` runs the skill in an isolated subagent — no conversation history:

```yaml
---
name: deep-research
context: fork
agent: Explore
---
Research $ARGUMENTS thoroughly. Find relevant files, read them, summarize findings with file references.
```

Available built-in agents: `Explore`, `Plan`, `general-purpose`. Or use any custom agent from `agents/`.

## Supporting files

Keep `SKILL.md` under ~500 lines. Move detail to separate files and reference them:

```
my-skill/
├── SKILL.md           # overview + navigation (required)
├── reference.md       # detailed API docs
├── examples.md        # usage examples
└── scripts/
    └── helper.sh      # utility scripts
```

Reference from SKILL.md so Claude knows they exist:
```markdown
For complete API details, see [reference.md](reference.md).
```

## Writing concise skills

Only add what Claude doesn't already know. Every token in an invoked skill stays in context for the session.

**Good** (~50 tokens):
```markdown
## Extract PDF text
Use pdfplumber:
```python
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
```

**Bad** (~150 tokens): Explains what PDFs are, why pdfplumber was chosen, how to install it.

Match specificity to fragility:
- Multiple valid approaches → text instructions with latitude
- Exact sequence required → numbered steps or pseudocode
- Exact commands required → literal script

## Description quality

A good description makes Claude use the skill at the right time and skip it otherwise.

- Put the primary use case first
- Include phrases users would naturally type
- Be specific enough that similar skills are distinguishable

```yaml
# Too vague — Claude won't know when to trigger it
description: Handles code stuff

# Good — specific triggers, clear scope
description: Review code for bugs, security issues, and performance. Use when reviewing PRs, checking recent changes, or asked to audit a file.
```
