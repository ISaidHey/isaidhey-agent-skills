# Plugin Dependencies

Declare other plugins your plugin requires. Claude Code installs them automatically.

## Basic declaration

In `.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "version": "2.0.0",
  "dependencies": [
    "audit-logger",
    { "name": "secrets-vault", "version": "~2.1.0" }
  ]
}
```

- Bare string → tracks latest version from marketplace
- Object with `version` → semver range constraint

## Version range syntax

Uses npm semver. Common patterns:

| Range | Meaning |
|-------|---------|
| `"~2.1.0"` | `>=2.1.0 <2.2.0` — patch updates only |
| `"^2.0.0"` | `>=2.0.0 <3.0.0` — minor + patch updates |
| `">=1.4.0"` | Any version at or above 1.4.0 |
| `"=2.1.0"` | Exactly 2.1.0, no updates |

Pre-release versions excluded unless range opts in: `"^2.0.0-0"`.

## Dependency fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Plugin name. Resolves within the same marketplace. |
| `version` | No | Semver range. Omit to track latest. |
| `marketplace` | No | Resolve from a different marketplace (requires allowlist — see below). |

## Cross-marketplace dependencies

By default, a dependency must live in the same marketplace as the declaring plugin. To allow another marketplace, the **root marketplace** (the one the user is installing from) must declare it:

```json
{
  "name": "acme-tools",
  "allowCrossMarketplaceDependenciesOn": ["acme-shared"],
  "plugins": [...]
}
```

Only the root marketplace's allowlist is checked — trust doesn't chain through intermediaries.

## When multiple plugins constrain the same dependency

Claude Code intersects all ranges and resolves to the highest version satisfying all of them:

| Plugin A requires | Plugin B requires | Result |
|-------------------|-------------------|--------|
| `^2.0` | `>=2.1` | Highest `2.x` at or above `2.1.0` |
| `~2.1` | `~3.0` | Install fails with `range-conflict` |
| `=2.1.0` | (none) | Stays at `2.1.0`, auto-update skipped |

## Tagging your plugin for use as a dependency

If other plugins will constrain versions of your plugin, tag each release:

```bash
claude plugin tag --push
```

Creates a `{plugin-name}--v{version}` git tag. Without tags, version ranges can't be resolved.

## Dependency errors

| Error | Meaning | Fix |
|-------|---------|-----|
| `dependency-unsatisfied` | Dep not installed or disabled | Run `claude plugin install <dep>@<marketplace>` |
| `range-conflict` | No version satisfies all constraints | Uninstall one conflicting plugin or ask upstream to widen range |
| `dependency-version-unsatisfied` | Installed version outside declared range | Re-resolve: `claude plugin install <dep>@<marketplace>` |
| `no-matching-tag` | No `{name}--v*` tag satisfies the range | Check upstream tagged releases, or relax your range |

Check errors: `claude plugin list --json` → read `errors` field per plugin.

## Cleaning up

Remove auto-installed deps no longer needed by any installed plugin:

```bash
claude plugin prune

# Or when uninstalling:
claude plugin uninstall my-plugin --prune
```

Requires Claude Code v2.1.121+.
