# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repo.

## What This Repo Is

Claude Code plugin marketplace. `scaffold-skills` plugin ships two skills for scaffolding plugin infrastructure:

- `scaffold-skills:marketplace-init` — interactive scaffold for `marketplace.json`
- `scaffold-skills:plugin-init` — interactive scaffold for plugin dir + optional skill + optional marketplace registration

## Development Commands

No build system. No package manager. Run scripts directly.

```bash
# marketplace-init
bash scaffold-skills/skills/marketplace-init/scripts/init.sh --help
bash scaffold-skills/skills/marketplace-init/scripts/init.sh \
  --name my-marketplace --dir /tmp/test-market \
  --owner-name "Test User" --owner-email test@example.com --description "test"

# plugin-init
bash scaffold-skills/skills/plugin-init/scripts/init.sh --help
bash scaffold-skills/skills/plugin-init/scripts/init.sh \
  --name my-plugin --dir /tmp/test-plugin --description "test" --author-name "Test User"
```

Runtime deps: `jq`, GNU `realpath` (macOS: `brew install coreutils`). `claude` CLI optional (plugin-init post-creation validation only).

## Architecture

Each skill: two-file model.

- **`SKILL.md`** — manifest read by Claude Code; drives conversation flow, collects args, calls `init.sh`, renders JSON result
- **`scripts/init.sh`** — worker; validates input, creates files, emits single JSON to stdout

SKILL.md = UX source of truth. `init.sh` = pure mechanics, never prompts user.

### `marketplace-init/scripts/init.sh`

Field collection entirely in bash:
- `:25-53` — arg parsing + reserved name check (`is_reserved`)
- `:62-81` — name validation
- `:83-128` — directory selection menu (numbered list of candidates)
- `:129-157` — owner name / email / description prompts + path canonicalization
- `:159-193` — create dirs, write `marketplace.json` via `jq`
- `:194-196` — emit JSON to stdout

### `plugin-init/scripts/init.sh`

Discrete fns called from main flow:
- `:87` `create_plugin()` — writes `.claude-plugin/plugin.json`
- `:124` `create_skill()` — writes `skills/<name>/SKILL.md` placeholder
- `:150` `register_plugin()` — appends plugin entry to `marketplace.json`; discovers `skills/*/SKILL.md`, includes in entry's `skills` array
- `:217-221` — main flow: calls fns conditionally based on flags

## Critical Constraints

- All user-supplied values pass through `jq --arg` — never string-interpolated (JSON injection prevention)
- Name validation regex: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$` — enforced in `init.sh`, not SKILL.md
- Path canonicalization via `realpath --canonicalize-missing` — prevents traversal
- `plugin-init` uses `--no-create` flag to re-enter script for skill creation + marketplace registration without re-running plugin creation

## Repository Layout

```
.claude-plugin/marketplace.json     ← marketplace catalog
scaffold-skills/                    ← the plugin
  .claude-plugin/plugin.json
  skills/
    marketplace-init/
      SKILL.md
      scripts/init.sh
      docs/                         ← schema, validation, distribution, sources, versioning
    plugin-init/
      SKILL.md
      scripts/init.sh
      docs/                         ← schema, components, skill-authoring, distribution, dependencies
docs/
  raw/                              ← upstream Claude Code docs (source material for distilled docs)
  decisions/                        ← ADRs (0001 marketplace-init, 0002 plugin-init)
```

## Reference Docs

- `scaffold-skills/skills/marketplace-init/docs/schema.md` — `marketplace.json` field reference
- `scaffold-skills/skills/marketplace-init/docs/validation.md` — validation rules & testing
- `scaffold-skills/skills/marketplace-init/docs/distribution.md` — hosting & distribution
- `scaffold-skills/skills/plugin-init/docs/schema.md` — `plugin.json` field reference
- `scaffold-skills/skills/plugin-init/docs/components.md` — all plugin component types
- `scaffold-skills/skills/plugin-init/docs/skill-authoring.md` — writing effective SKILL.md files
- `docs/decisions/0001-marketplace-init-skill.md` — ADR for marketplace-init design
- `docs/decisions/0002-plugin-init-skill.md` — ADR for plugin-init design