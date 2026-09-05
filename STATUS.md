# Status - 2026-09-05

- Fixed both P1 installer findings with a shared scaffold allowlist, path/link preflight,
  and source/destination overlap checks in Bash and PowerShell.
- Existing vaults and Git checkouts are never staged or committed. Fresh empty vaults
  receive an initial commit containing only the newly installed scaffold files.
- Added regression coverage for private-file exclusion, real Git worktrees, preserved
  commits/indexes, repeat installs, overlap, missing files, and redirected paths.
- Regression checks pass locally in Bash and PowerShell 7.6, and in GitHub Actions on
  Linux (22 checks) and Windows using Windows PowerShell (11 checks), with no skips.
- Source citation formatting and missing license text remain separate audit items.
