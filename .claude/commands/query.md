---
description: Ask the wiki a question (answers only from vault content)
---

Run the **Query** operation defined in `CLAUDE.md`.

1. Read `index.md`, then the relevant `wiki/` pages; fall back to `raw/` for detail.
2. Answer **only** from what's in the vault. If the wiki doesn't support an answer, say so
   plainly - do not fill the gap with outside knowledge presented as vault fact.
3. Cite the wiki pages you used. If the answer is substantial, save it to `outputs/`.
4. Append a `## [<today>] query | <question>` entry to `log.md`.

Question: $ARGUMENTS
