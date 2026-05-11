# Validation and Testing

## Validate Your Marketplace

From the marketplace directory:

```bash
claude plugin validate .
```

Or from within Claude Code:

```
/plugin validate .
```

Checks `plugin.json`, skill/agent/command frontmatter, and `hooks/hooks.json` for syntax and schema errors. Safe to run repeatedly.

## Add and Test

```bash
# Add via CLI
claude plugin marketplace add ./my-marketplace

# Add from within Claude Code
/plugin marketplace add ./my-marketplace

# Install a plugin from it
/plugin install my-plugin@my-marketplace-name

# List installed plugins
claude plugin list
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `File not found: .claude-plugin/marketplace.json` | Missing manifest | Create `.claude-plugin/marketplace.json` with required fields |
| `Invalid JSON syntax: Unexpected token...` | JSON parse error | Check for missing/extra commas, unquoted strings |
| `Duplicate plugin name "x" found in marketplace` | Two entries share same `name` | Give each plugin a unique `name` |
| `plugins[0].source: Path contains ".."` | Source path traverses outside marketplace root | Use paths relative to marketplace root without `..` |
| `YAML frontmatter failed to parse: ...` | Invalid YAML in a skill or agent file | Fix the YAML syntax; the file loads with no metadata at runtime |
| `Invalid JSON syntax: ...` (hooks.json) | Malformed `hooks/hooks.json` | Fix JSON — a malformed hooks.json blocks the entire plugin from loading |

## Non-Blocking Warnings

- `Marketplace has no plugins defined` — add at least one entry to `plugins[]`
- `No marketplace description provided` — add top-level `description`
- `Plugin name "x" is not kebab-case` — rename to lowercase letters, digits, and hyphens only (required for Claude.ai marketplace submission)
