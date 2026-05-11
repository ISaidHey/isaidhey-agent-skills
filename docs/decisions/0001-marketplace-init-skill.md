---
type: decision
id: "0001"
title: "Automate marketplace scaffolding with marketplace-init skill"
status: active
date: 2026-05-10
superseded_by: ""
---

## Context

Creating Claude Code plugin marketplaces has come up multiple times across different contexts — team skills, internal devcontainer skills, personal skills. Manual scaffolding (creating `.claude-plugin/marketplace.json`, the directory structure, getting all required fields right) is repetitive and error-prone. This was also undertaken as an educational exercise in skill authoring.

## Decision

**Build a `marketplace-init` skill in the `isaidhey-agent-skills` plugin that scaffolds a Claude Code marketplace via an interactive wizard.**

The skill is a thin orchestrator: `SKILL.md` calls `scripts/init.sh`, passing any pre-supplied arguments as `--flag value` pairs; the script handles all prompting, validation, and file creation; on success it emits a single JSON line that the skill parses to render next steps.

## Implementation Notes

### JSON generation — jq, not sed+template

The original spec implied a `marketplace.template.json` + sed substitution approach. This was replaced during implementation with `jq -n --arg` for two reasons:

1. **Correctness**: sed re-interprets escape sequences in replacement strings. A value like `foo\bar` passed through `json_escape` → sed becomes `foo\\bar` in the file, not the intended `foo\bar`. Values containing newlines or control characters produce invalid JSON with no error. `jq --arg` handles all escaping correctly regardless of input content.
2. **Simplicity**: removes the template file, the `json_escape` helper, and the fragile trailing-comma removal for the optional email field.

### Name validation regex

`^[a-z][a-z0-9]*(-[a-z0-9]+)*$` — tighter than the spec's `^[a-z][a-z0-9-]*$`. The stricter form rejects trailing hyphens (`my-name-`), consecutive double hyphens (`my--name`), and hyphen-only suffixes that the original regex permitted.

### Path canonicalization

`realpath --canonicalize-missing` applied to `$DIR` before any filesystem writes. Prevents path traversal via arguments like `../../etc`.

### Runtime dependencies

- **`jq`**: required for JSON generation and stdout output. Not in the original spec. Fails with a clear "command not found" error if absent.
- **`realpath` (GNU coreutils)**: Linux-native. macOS requires `brew install coreutils` unless using a devcontainer.

## Consequences

Easier: adding a new marketplace should be as simple as invoking the skill and answering prompts — no manual file creation or schema lookup required.

Harder: introduces a runtime dependency on `jq` that was not present in the original design. macOS users outside a devcontainer need GNU coreutils for `realpath --canonicalize-missing`.

**Re-evaluate if:** invoking the skill still requires as much manual tweaking afterward as doing it by hand — that signals the wizard needs refinement or the approach needs reassessment.

## Invariants

- All user-controlled values (name, description, owner fields) **must** be passed to `jq` via `--arg`, never string-interpolated into a JSON literal. This prevents JSON corruption and injection regardless of input content.
- JSON generation **must** use `jq`, not string concatenation or sed-on-template substitution.
- Name validation **must** use `^[a-z][a-z0-9]*(-[a-z0-9]+)*$` or stricter — the looser form `[a-z0-9-]*` silently accepts invalid kebab-case.
