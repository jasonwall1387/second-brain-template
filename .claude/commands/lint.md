---
description: Monthly wiki health audit - proposes fixes, does not auto-rewrite
---

Run the **Lint** operation defined in `CLAUDE.md`. This is an audit, not an autonomous
cleanup - produce a report for the human to review and approve.

Check the whole wiki for:
- Contradictions between pages or across dated claims within a page.
- Stale facts (old `updated:` dates; claims a newer source has superseded).
- Broken `[[links]]` and `[[source:]]` citations pointing at missing files.
- Orphan pages (no inbound links) and missing cross-references.
- Pages whose claims are no longer traceable to a cited source (possible drift/hallucination).

Write the findings to `outputs/lint-<today>.md` as a prioritized checklist (do NOT rewrite
wiki pages). Append a `## [<today>] lint | <summary>` entry to `log.md`.

$ARGUMENTS
