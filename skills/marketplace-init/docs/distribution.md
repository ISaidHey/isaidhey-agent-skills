# Distributing Your Marketplace

## Host on GitHub (recommended)

Push your directory to a GitHub repository. The `.claude-plugin/marketplace.json` file is all Claude Code needs to locate the marketplace.

Users add it with:

```bash
# GitHub shorthand
claude plugin marketplace add owner/repo

# Pin to a branch or tag
claude plugin marketplace add owner/repo@v2.0

# Within Claude Code
/plugin marketplace add owner/repo
```

Any git host works (GitLab, Bitbucket, self-hosted HTTPS). Pass the full URL:

```bash
claude plugin marketplace add https://gitlab.example.com/team/plugins.git
```

## Require for Your Team

Add to `.claude/settings.json` and commit it to your repo. When teammates open the project, Claude Code prompts them to install the marketplace automatically.

```json
{
  "extraKnownMarketplaces": {
    "your-marketplace-name": {
      "source": {
        "source": "github",
        "repo": "your-org/your-repo"
      }
    }
  }
}
```

To also enable specific plugins by default:

```json
{
  "enabledPlugins": {
    "my-plugin@your-marketplace-name": true
  }
}
```

## Private Repositories

**Manual install/update**: Claude Code uses your existing git credentials (GitHub CLI, macOS Keychain, `git-credential-store`).

**Background auto-updates**: require an environment variable since there is no interactive prompt at startup:

| Provider  | Variable               |
|-----------|------------------------|
| GitHub    | `GITHUB_TOKEN` or `GH_TOKEN` |
| GitLab    | `GITLAB_TOKEN` or `GL_TOKEN` |
| Bitbucket | `BITBUCKET_TOKEN`      |

```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```
