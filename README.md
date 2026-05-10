# isaidhey-agent-skills

---

## Skills

### `marketplace-init`

Scaffolds a new Claude Code plugin marketplace interactively. Creates `.claude-plugin/marketplace.json` with schema, name, owner, and version fields. Prompts for any fields not supplied as arguments.

```
/marketplace-init [name] [dir] [owner-name] [owner-email] [description]
```

**Runtime dependencies**

| Dependency | Linux | macOS |
|------------|-------|-------|
| `jq` | `apt install jq` | `brew install jq` |
| GNU `realpath` | pre-installed | `brew install coreutils` |
