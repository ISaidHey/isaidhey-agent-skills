# Plugin Source Types

Each plugin entry in `plugins[]` requires `name` and `source`. The `source` field tells Claude Code where to fetch the plugin. Once fetched, plugins are cached at `~/.claude/plugins/cache`.

## Relative Path

For plugins in the same repository. Must start with `./`. Resolves relative to the marketplace root (the directory containing `.claude-plugin/`).

```json
{ "name": "my-plugin", "source": "./plugins/my-plugin" }
```

> Only works when the marketplace is added via Git. Fails with URL-based marketplaces (the JSON file is fetched but the relative files aren't).

## GitHub

```json
{
  "name": "my-plugin",
  "source": {
    "source": "github",
    "repo": "owner/repo",
    "ref": "v2.0.0",
    "sha": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
  }
}
```

`ref` (branch/tag) and `sha` (exact commit) are optional. Both omitted = default branch.

## Git URL

Works with GitLab, Bitbucket, self-hosted, or any HTTPS/SSH git remote.

```json
{
  "name": "my-plugin",
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git",
    "ref": "main"
  }
}
```

## Git Subdirectory (monorepo)

Sparse clone — fetches only the named subdirectory. Minimises bandwidth for large monorepos.

```json
{
  "name": "my-plugin",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/org/monorepo.git",
    "path": "tools/my-plugin",
    "ref": "v2.0.0"
  }
}
```

## npm

```json
{
  "name": "my-plugin",
  "source": {
    "source": "npm",
    "package": "@acme/claude-plugin",
    "version": "2.1.0",
    "registry": "https://npm.example.com"
  }
}
```

`version` (semver or range) and `registry` (private registry URL) are optional.
