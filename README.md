# isaidhey-agent-skills

A Claude Code plugin marketplace with skills for scaffolding Claude Code plugins and marketplaces.

## Install

```
/plugin marketplace add github.com/isaidhey-agent-skills
/plugin install scaffold-skills@isaidhey-agent-skills
/plugin install isaidhey@isaidhey-agent-skills
```

---

## Plugin: `scaffold-skills`

Skills for scaffolding Claude Code plugins and marketplaces.

### `scaffold-skills:marketplace-init`

Scaffolds a new Claude Code plugin marketplace interactively. Creates `.claude-plugin/marketplace.json` with schema, name, owner, and version fields. Prompts for any fields not supplied as arguments.

```
/scaffold-skills:marketplace-init [name] [dir] [owner-name] [owner-email] [description]
```

**Runtime dependencies**

| Dependency | Linux | macOS |
|------------|-------|-------|
| `jq` | `apt install jq` | `brew install jq` |
| GNU `realpath` | pre-installed | `brew install coreutils` |

### `scaffold-skills:plugin-init`

Scaffolds a new Claude Code plugin directory with a `plugin.json` manifest. Optionally creates a first skill placeholder and registers the plugin in a local marketplace.

```
/scaffold-skills:plugin-init [name] [dir] [description] [author-name] [author-email] [skill-name] [skill-description]
```

**Runtime dependencies**

| Dependency | Linux | macOS |
|------------|-------|-------|
| `jq` | `apt install jq` | `brew install jq` |
| GNU `realpath` | pre-installed | `brew install coreutils` |
| `claude` CLI | optional — post-creation validation only | optional |

---

## Plugin: `isaidhey`

Core day-to-day skills.

### `isaidhey:decided`

Documents architectural decisions (ADRs) in a frontmatter-backed markdown vault. Creates, supersedes, retires, rejects, and reviews decisions. Discovers the ADR directory from context and persists it to `CLAUDE.md` on first use.

```
/isaidhey:decided
```
