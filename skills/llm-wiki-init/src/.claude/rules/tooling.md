# Tooling Rules

## File search: use rg, not grep

Use `rg` (ripgrep) for all local file searches. Never use `grep` for searching files in this repo.

```bash
# Good
rg "pattern" wiki/
rg "^title:" wiki/concepts/

# Bad
grep -r "pattern" wiki/
```

`grep` is acceptable only when filtering stdin (piped output from another command) — that is not a file search and not a violation.

This applies to all skills, agent instructions, and ad-hoc searches. Source: ADR-0008.
