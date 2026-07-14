# log.md - operation log (append-only)

One entry per operation, newest at the bottom. Never rewrite old entries. Prefixed so it's
greppable: `## [YYYY-MM-DD] <op> | <subject>`.

## [2026-01-01] install | Second Brain template initialized
- Scaffolded `raw/ wiki/ outputs/`, the schema (`CLAUDE.md`), and the `/ingest` `/query`
  `/lint` commands.
- Seeded example wiki pages so the vault is not blank. Delete them once real content lands.
- Next: drop your first sources into `raw/` and run `/ingest`.
