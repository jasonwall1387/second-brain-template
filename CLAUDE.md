# CLAUDE.md - Second Brain schema

This vault is an **AI-maintained second brain**, built on Andrej Karpathy's
"LLM Wiki" pattern (raw sources -> AI-owned wiki -> this schema file). You are the
librarian. The human curates sources; you summarize, file, and cross-reference them.

Read this file at the start of every session. Then read `index.md` (the wiki catalog)
before doing anything else - it is faster than scanning the tree.

---

## The three layers

| Layer | Owner | Rule |
|---|---|---|
| `raw/` | Human (curation only) | **Immutable.** You read from it; you NEVER edit or reorganize it. New source dumps land here. |
| `wiki/` | You | Synthesized markdown pages. You write and maintain all of it. The human reads it. |
| `outputs/` | You | Reports, answers, and artifacts you generate on request. |

Any **existing folders** the human already keeps in this vault are their **human notes**.
Treat them as read-only source material - ingest them into `wiki/` but do not move, rename,
or edit them. `Templates/` and `.obsidian/` are off-limits entirely.

> Adapt this: list your own top-level source folders here so the librarian knows what is
> human-curated ground truth versus what it owns.

---

## The three operations

### Ingest (`/ingest`)
Turn raw source material into wiki knowledge.
1. Read `index.md` first.
2. For each new/changed source: read it fully. Identify the entities, concepts, projects,
   and decisions it contains.
3. **Update existing wiki pages** where the source adds to or changes what's already known.
   Create new pages only for genuinely new subjects. Do not append a new page for a subject
   that already has one - this is how staleness creeps in.
4. Every factual claim in a wiki page cites its source inline: `([[source: path/to/note.md]])`.
5. Backlink every entity/concept to at least one related page. Cap links at ~7 per page;
   do not create a page for a subject mentioned only once - link it inline instead.
6. If a source lives outside `raw/` (an existing human note), cite it at its real vault path.
   If the human drops something into `raw/`, move it to `raw/processed/` after ingesting it.
7. Update `index.md` and append a `log.md` entry.

### Query (`/query` or just ask)
Answer questions against the wiki.
1. Read `index.md`, then the relevant wiki pages. Fall back to `raw/` for detail.
2. Answer only from what's in the vault. If the wiki doesn't support an answer, say so -
   do not fill the gap with outside knowledge presented as vault fact.
3. Cite the wiki pages you used. Substantial answers get saved to `outputs/`.
4. Append a `log.md` entry.

### Lint (`/lint`) - run monthly, review the output yourself
Audit the wiki for rot. Produce a report to `outputs/lint-YYYY-MM-DD.md`; **do not
autonomously rewrite** - lint proposes, the human approves.
- Contradictions between pages (or within a page across dated claims).
- Stale facts: a `updated:` date far in the past, or a claim a newer source has superseded.
- Broken `[[links]]` and `[[source:]]` citations pointing at missing files.
- Orphan pages (no inbound links) and missing cross-references.
- Pages whose claims are no longer traceable to a cited source (possible drift/hallucination).
Append a `log.md` entry noting what the pass found.

---

## Discipline rules (these prevent the known failure modes)

1. **No invented facts.** Never add anything not present in a cited source. If you infer or
   synthesize, mark it explicitly (e.g. `> Synthesis:`), never as sourced fact.
2. **Cite everything.** Every claim traces to a `[[source:]]`. A wiki page with no sources
   is a bug.
3. **Update, don't append.** When a fact changes, edit the page and bump `updated:`. Keep a
   one-line `changed:` note if the old value mattered. Append-only pages rot.
4. **Recency wins, visibly.** When sources conflict, prefer the newest, keep the date on the
   claim, and flag the conflict rather than silently picking a winner.
5. **Raw is ground truth.** Quote raw verbatim when precision matters. Never let the wiki
   become the only record of something - the source note is the anchor.
6. **Full-file writes.** Prefer writing a whole file over in-place edits. (If this vault sits
   on a file-sync service like Dropbox / iCloud / Synology Drive, partial edits can race the
   sync layer. Write the complete file.)
7. **You are the reader.** Wiki pages are written for a future AI agent to retrieve and reason
   over, not for human browsing. Machine-readable structure, a summary line at top, dated
   claims, consistent frontmatter.

## Secrets rule (assume this vault may hold live secrets - treat it as such)

Personal notes often contain credentials, tokens, one-time codes, SSH details, and PII
(password managers' exports, `*.png` token screenshots, "account setup" notes, etc.).

- **Never reproduce a secret value into a wiki page or output.** Not tokens, keys, IDs,
  passwords, one-time codes, or private URLs.
- The wiki may note that a credential *exists* and *where it lives* ("the mail provider's
  API token is in [[source: accounts/mail-setup.md]]; secrets belong in a secrets manager").
- Keep real secrets in a dedicated secrets manager, never hardcoded, never committed.
- **Do not push this vault to any remote until a secrets audit clears it.** Local git is fine;
  a public or shared remote is not, until you have scrubbed or `.gitignore`d sensitive notes.

---

## Frontmatter schema (every wiki page)

```yaml
---
type: entity | concept | project | decision | reference
title: Canonical Name
status: active | archived | idea | blocked
created: 2026-01-01
updated: 2026-01-01
source: ["path/to/source.md"]   # every raw source this page draws from
tags: [work, client]            # 5-10 vault-wide tags max; reuse, don't invent
confidence: high | medium | low # optional; low = thin sourcing
---
```

Body convention: one-sentence summary at top, then dated claims with inline
`([[source: ...]])` citations, then a `## Links` section of `[[backlinks]]`.

## Folder + naming conventions

```
wiki/
  entities/    people, companies, tools, accounts (acme-corp.md, my-crm-tool.md)
  concepts/    ideas, theses, frameworks (positioning-thesis.md)
  projects/    active builds and engagements (client-a-website.md)
  decisions/   dated calls with rationale (2026-01-15-pick-a-stack.md)
  reference/   durable facts, how-tos, account maps (billing-accounts.md)
```
Filenames: lowercase, hyphenated, stable. Decisions prefixed with the date.

## index.md and log.md

- `index.md` - the catalog of everything in `wiki/`, grouped by type, one line each with a
  wiki-link and a short descriptor. Rebuild/update it on every ingest.
- `log.md` - append-only. One entry per operation, prefixed so it's greppable:
  `## [2026-01-01] ingest | Subject` then a few bullets. Never rewrite old entries.

## Scaling (later, not now)

Flat `index.md` works to ~100-200 pages. Past that, add hybrid search (`qmd` - local
BM25+vector for markdown, has a CLI and MCP server) rather than growing the index. Early on
the wiki is small; keep the index tight and this is a later concern.
