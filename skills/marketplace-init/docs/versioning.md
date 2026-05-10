# Version Management

## Resolution Order

Claude Code picks the plugin's version from the first of these that is set:

1. `version` in the plugin's `plugin.json`
2. `version` in the plugin's marketplace entry (`marketplace.json`)
3. Git commit SHA of the plugin's source (for git-backed sources)
4. `"unknown"` — for npm sources or local dirs not inside a git repo

## Two Approaches

### Explicit version (stable releases)

Set `"version": "1.0.0"` in `plugin.json` or the marketplace entry.

- Users receive updates **only when you bump this field**
- Pushing new commits without bumping has no effect
- Best for published plugins with stable release cycles

Follow semver: MAJOR for breaking changes, MINOR for new features, PATCH for fixes.

> **Warning:** If both `plugin.json` and the marketplace entry set `version`, `plugin.json` wins silently. Set it in one place only.

### Commit-SHA version (active development)

Omit `version` from both `plugin.json` and the marketplace entry.

- Every new commit is a new version
- Users get updates on every push
- Best for internal or team plugins under active development

## Release Channels

To support stable/latest channels, create two marketplace files pointing to different `ref` values of the same repo:

### Example

```json
{ "name": "stable-tools", "plugins": [{ "name": "formatter", "source": { "source": "github", "repo": "org/formatter", "ref": "stable" } }] }
```

```json
{ "name": "latest-tools", "plugins": [{ "name": "formatter", "source": { "source": "github", "repo": "org/formatter", "ref": "latest" } }] }
```

Each channel must resolve to a different version string — otherwise auto-update skips it as already installed.
