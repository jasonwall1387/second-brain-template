---
description: Ingest raw sources into the wiki (Karpathy LLM-Wiki pattern)
---

Run the **Ingest** operation defined in `CLAUDE.md`.

1. Read `CLAUDE.md` and `index.md` first.
2. Determine what to ingest:
   - If the user named specific files/folders, use those.
   - Otherwise, ingest everything new in `raw/` (anything not yet in `raw/processed/`),
     plus any existing human notes the user points at.
3. For each source: read it fully, then update existing wiki pages or create new ones per
   the discipline rules (cite every claim inline with `([[source: ...]])`, update don't
   append, no invented facts, never reproduce secrets).
4. Rebuild `index.md` and append a `## [<today>] ingest | <subject>` entry to `log.md`.
5. Move ingested files from `raw/` to `raw/processed/` (do not touch human notes in place).
6. Report what pages you created vs. updated, and anything you couldn't ground in a source.

$ARGUMENTS
