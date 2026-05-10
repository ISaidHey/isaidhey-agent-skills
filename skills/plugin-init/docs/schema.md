# plugin.json Schema Reference

The manifest lives at `.claude-plugin/plugin.json` inside your plugin root. It's optional — Claude Code auto-discovers components in default locations and uses the directory name as the plugin name if you omit it. Use a manifest when you need metadata or non-default paths.

## Required fields

If you include a manifest, only `name` is required.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `name` | string | Kebab-case identifier. Used as namespace prefix for all components: skills become `/<name>:<skill>`, agents `<name>:<agent>`, etc. | `"my-plugin"` |

## Metadata fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `version` | string | Semver. If set, users only get updates when you bump it. If omitted, every git commit is a new version (good for active development). | `"1.2.0"` |
| `description` | string | Shown in plugin manager | `"Deployment automation tools"` |
| `author` | object | `{ name, email?, url? }` | `{"name": "Dev Team", "email": "dev@co.com"}` |
| `homepage` | string | Docs URL | `"https://docs.example.com"` |
| `repository` | string | Source URL | `"https://github.com/user/plugin"` |
| `license` | string | SPDX identifier | `"MIT"`, `"Apache-2.0"` |
| `keywords` | array | Discovery tags | `["deployment", "ci-cd"]` |
| `$schema` | string | JSON Schema URL for editor autocomplete. Ignored at load time. | `"https://json.schemastore.org/claude-code-plugin-manifest.json"` |

## Component path fields

By default, Claude Code scans standard locations (e.g., `skills/`, `agents/`, `hooks/hooks.json`). These fields let you use custom paths.

| Field | Type | Replaces or extends default? | Example |
|-------|------|------------------------------|---------|
| `skills` | string\|array | **Extends** — default `skills/` is always scanned too | `"./custom/skills/"` |
| `commands` | string\|array | **Replaces** default `commands/` | `"./custom/commands/"` |
| `agents` | string\|array | **Replaces** default `agents/` | `"./custom-agents/reviewer.md"` |
| `hooks` | string\|array\|object | Own merge rules (all sources combined) | `"./config/hooks.json"` |
| `mcpServers` | string\|array\|object | Own merge rules | `"./mcp-config.json"` |
| `lspServers` | string\|array\|object | Own merge rules | `"./.lsp.json"` |
| `outputStyles` | string\|array | **Replaces** default `output-styles/` | `"./styles/"` |
| `experimental.themes` | string\|array | **Replaces** default `themes/` | `"./themes/"` |
| `experimental.monitors` | string\|array | **Replaces** default `monitors/` | `"./monitors.json"` |

All paths must be relative to the plugin root and start with `./`.

## Advanced fields

### `userConfig` — prompt users at enable time

Declare values Claude Code should collect when a user enables your plugin, instead of requiring manual `settings.json` edits.

```json
{
  "userConfig": {
    "api_endpoint": {
      "type": "string",
      "title": "API endpoint",
      "description": "Your team's API endpoint"
    },
    "api_token": {
      "type": "string",
      "title": "API token",
      "description": "Auth token",
      "sensitive": true
    }
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | `string`, `number`, `boolean`, `directory`, or `file` |
| `title` | Yes | Label in dialog |
| `description` | Yes | Help text |
| `sensitive` | No | Masks input, stores in keychain not `settings.json` |
| `required` | No | Fail validation if empty |
| `default` | No | Value when user provides nothing |
| `multiple` | No | Allow array of strings (string type only) |
| `min` / `max` | No | Bounds for number type |

Values available as `${user_config.KEY}` in hooks, MCP/LSP configs, monitors, skills, and agents. Exported as `CLAUDE_PLUGIN_OPTION_<KEY>` env vars to subprocesses.

### `dependencies` — require other plugins

```json
{
  "dependencies": [
    "audit-logger",
    { "name": "secrets-vault", "version": "~2.1.0" }
  ]
}
```

See [dependencies.md](./dependencies.md) for full details.

## Complete example

```json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Does useful things",
  "author": { "name": "Your Name", "email": "you@example.com" },
  "homepage": "https://github.com/you/my-plugin",
  "repository": "https://github.com/you/my-plugin",
  "license": "MIT",
  "keywords": ["productivity"]
}
```
