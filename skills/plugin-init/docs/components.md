# Plugin Components

Everything you can add to a plugin beyond the initial scaffold. All directories go at the **plugin root** — not inside `.claude-plugin/`.

## Directory layout

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # manifest only
├── skills/                  # skills as <name>/SKILL.md
├── commands/                # skills as flat .md files (legacy; use skills/ for new work)
├── agents/                  # subagent definitions
├── hooks/
│   └── hooks.json           # event handlers
├── bin/                     # executables added to Bash PATH
├── .mcp.json                # MCP server configs
├── .lsp.json                # LSP server configs
├── monitors/
│   └── monitors.json        # background monitors
├── output-styles/           # output style definitions
├── themes/                  # color themes (experimental)
└── settings.json            # default settings applied at enable time
```

## Skills

**Location:** `skills/<name>/SKILL.md`  
**Namespace:** `/<plugin-name>:<skill-name>`

```
skills/
├── code-reviewer/
│   ├── SKILL.md
│   └── scripts/             # optional supporting scripts
└── pdf-processor/
    ├── SKILL.md
    └── reference.md         # optional supporting docs
```

Auto-discovered when the plugin is installed. See [skill-authoring.md](./skill-authoring.md) for how to write effective SKILL.md files.

## Agents

**Location:** `agents/<name>.md`  
**Access:** appear in `/agents`, can be invoked by Claude automatically

```markdown
---
name: security-reviewer
description: Reviews code for security issues. Use when reviewing PRs or analyzing untrusted input.
model: sonnet
effort: medium
maxTurns: 20
disallowedTools: Write, Edit
---

System prompt for the agent...
```

Supported frontmatter: `name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, `isolation` (`"worktree"` only).

Not supported for security reasons: `hooks`, `mcpServers`, `permissionMode`.

## Hooks

**Location:** `hooks/hooks.json` (or inline in `plugin.json`)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh"
          }
        ]
      }
    ]
  }
}
```

Hook types: `command`, `http`, `mcp_tool`, `prompt`, `agent`.

Key events: `SessionStart`, `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `FileChanged`, `CwdChanged`, `PreCompact`, `PostCompact`.

Use `${CLAUDE_PLUGIN_ROOT}` for all paths inside hook commands — it resolves to the plugin's install directory.

Make hook scripts executable: `chmod +x scripts/your-script.sh`.

## MCP Servers

**Location:** `.mcp.json` (or inline in `plugin.json`)

```json
{
  "mcpServers": {
    "my-server": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": { "DATA_PATH": "${CLAUDE_PLUGIN_DATA}/data" }
    }
  }
}
```

MCP servers start automatically when the plugin is enabled. Tools appear in Claude's standard toolkit.

Use `${CLAUDE_PLUGIN_DATA}` for state that must survive plugin updates (e.g., `node_modules`, caches).

## LSP Servers

**Location:** `.lsp.json` (or inline in `plugin.json`)

Gives Claude real-time code intelligence: diagnostics, go-to-definition, find-references.

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": { ".go": "go" }
  }
}
```

The language server binary must be installed separately by the user. Optional fields: `args`, `transport`, `env`, `initializationOptions`, `settings`, `startupTimeout`, `restartOnCrash`.

## Background Monitors

**Location:** `monitors/monitors.json`

Runs persistent shell commands and delivers each stdout line to Claude as a notification.

```json
[
  {
    "name": "error-log",
    "command": "tail -F ./logs/error.log",
    "description": "Application error log"
  },
  {
    "name": "deploy-status",
    "command": "${CLAUDE_PLUGIN_ROOT}/scripts/poll-deploy.sh",
    "description": "Deployment status",
    "when": "on-skill-invoke:deploy"
  }
]
```

`when` options: `"always"` (default, starts at session start) or `"on-skill-invoke:<skill-name>"` (starts on first dispatch of that skill).

Requires Claude Code v2.1.105+.

## `bin/` Executables

Files in `bin/` are added to the Bash tool's `PATH` while the plugin is enabled. Any file here can be called as a bare command in Bash tool calls — no full path needed.

## `settings.json` — Default settings

Applied when the plugin is enabled. Currently only `agent` and `subagentStatusLine` keys are supported.

```json
{
  "agent": "security-reviewer"
}
```

`"agent"` activates a plugin agent as the main thread, applying its system prompt and tool restrictions by default.

## Path variables

| Variable | Resolves to |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin's install directory. Changes on update — treat as ephemeral. |
| `${CLAUDE_PLUGIN_DATA}` | Persistent directory that survives updates (`~/.claude/plugins/data/<id>/`). Use for `node_modules`, caches, generated files. |
