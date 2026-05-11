# Marketplace Schema Reference

## Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Kebab-case identifier. Used in install commands: `/plugin install my-plugin@name`. |
| `owner` | object | Maintainer info — see Owner Fields below |
| `plugins` | array | Required. List of plugin entries — may be empty `[]` during setup |

## Owner Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Name of maintainer or team |
| `email` | No | Contact email |

## Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `$schema` | string | JSON Schema URL for editor autocomplete. Ignored by Claude Code at load time. Use `"https://json.schemastore.org/claude-code-marketplace.json"` |
| `description` | string | Brief marketplace description |
| `version` | string | Marketplace manifest version |
| `metadata.pluginRoot` | string | Base dir prepended to relative plugin source paths. E.g. `"./plugins"` lets you write `"source": "formatter"` instead of `"source": "./plugins/formatter"` |
| `allowCrossMarketplaceDependenciesOn` | array[string] | Marketplace names whose plugins can be auto-installed as dependencies |

## Reserved Names

These cannot be used for third-party marketplaces (enforced at submission):

- `claude-code-marketplace`
- `claude-code-plugins`
- `claude-plugins-official`
- `anthropic-marketplace`
- `anthropic-plugins`
- `agent-skills`
- `knowledge-work-plugins`
- `life-sciences`

Names that impersonate official marketplaces (e.g. `official-claude-plugins`, `anthropic-tools-v2`) are also blocked.
