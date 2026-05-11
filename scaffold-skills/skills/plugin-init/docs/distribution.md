# Distribution

How to share your plugin via a marketplace after building it.

## Marketplace overview

A marketplace is a `marketplace.json` file (in `.claude-plugin/`) that lists plugins and where to find them. Users add it once with `/plugin marketplace add <path-or-url>`, then install plugins with `/plugin install <plugin-name>@<marketplace-name>`.

Use `/marketplace-init` to scaffold the marketplace structure.

## Plugin source types

The `source` field in a marketplace entry tells Claude Code where to fetch the plugin:

| Type | Example | Notes |
|------|---------|-------|
| Relative path | `"./plugins/my-plugin"` | For plugins in the same repo as the marketplace |
| `github` | `{ "type": "github", "repo": "user/plugin-repo" }` | Fetches from GitHub; uses git SHA or version tag |
| `git-subdir` | `{ "type": "git-subdir", "repo": "user/mono-repo", "path": "plugins/my-plugin" }` | Plugin is a subdirectory of a monorepo |
| `url` | `{ "type": "url", "url": "https://example.com/my-plugin.zip" }` | Zip archive at any URL |
| `npm` | `{ "type": "npm", "package": "@scope/my-plugin" }` | npm package |

## Versioning strategy

Two approaches — choose one:

**Explicit version** (`version` set in `plugin.json`):
- Users only get updates when you bump `version`
- Every push without a version bump is invisible to users
- Best for stable releases with a changelog

**Commit-SHA version** (omit `version` from both `plugin.json` and marketplace entry):
- Every git commit = new version
- Users get updates automatically on every push
- Best for active development or internal/team plugins

> If you use explicit versions: bump `version` every release, follow semver (`MAJOR.MINOR.PATCH`), keep a `CHANGELOG.md`.

## Tagging releases for version constraints

If other plugins will depend on yours with version constraints, tag each release:

```bash
claude plugin tag --push
```

This creates a `{plugin-name}--v{version}` git tag derived from your manifest. Validates plugin contents and requires a clean working tree first.

Equivalent manual: `git tag my-plugin--v1.2.0 && git push --tags`

## Hosting options

**Same repo as marketplace** (simplest):
```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    └── my-plugin/
        └── .claude-plugin/
            └── plugin.json
```

**Separate plugin repo** (flexible, independent releases):
```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "source": { "type": "github", "repo": "you/my-plugin" },
      "description": "Does useful things"
    }
  ]
}
```

**Private repositories**: Works the same — users need read access to the repo. Claude Code uses their git credentials.

## Sharing with users

```bash
# Users add the marketplace
/plugin marketplace add https://github.com/you/your-marketplace

# Users install your plugin
/plugin install my-plugin@your-marketplace-name
```

Or via CLI:
```bash
claude plugin install my-plugin@your-marketplace-name
```

With scope flags:
```bash
# Available to everyone on this project (committed to .claude/settings.json)
claude plugin install my-plugin@marketplace --scope project
```

## Submit to official marketplace

Submit via Claude.ai or the Console:
- Claude.ai: claude.ai/settings/plugins/submit
- Console: platform.claude.com/plugins/submit

Once listed, users can discover and install without manually adding your marketplace.

## Testing before distribution

```bash
# Test locally without installing
claude --plugin-dir ./my-plugin

# Test a packaged zip
claude --plugin-url https://example.com/my-plugin.zip

# Validate manifest and structure
claude plugin validate ./my-plugin
```

Multiple plugins:
```bash
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

Live reload during development — no restart needed:
```
/reload-plugins
```
