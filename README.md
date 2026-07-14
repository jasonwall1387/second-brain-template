# Second Brain Template

A pre-built, AI-maintained **second brain** you can run in about ten minutes - built on
Andrej Karpathy's ["LLM Wiki" pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

You curate sources. An AI librarian reads them, writes a clean cross-referenced wiki, and
keeps it current - so your AI tools answer from *your* knowledge instead of generic advice.
Everything is plain Markdown on your own machine. You own it, and you can read it in any
editor forever.

> This is the open template. If you want it installed, populated from your existing tools,
> and maintained for you, that is a done-for-you service - see the bottom of this file.

## Why this exists

Notion makes you build the structure before you can capture anything. Obsidian gives you
ownership but leaves you assembling plugins. The Karpathy pattern solved the mental model -
let the AI own and maintain the wiki while you only curate sources - but implementing it from
scratch still takes an afternoon of setup. This repo is that setup, done.

## The three-layer model

| Layer | Who owns it | What it is |
|---|---|---|
| `raw/` | You | Your sources - exported notes, articles, transcripts, saved threads. The AI reads it, never edits it. |
| `wiki/` | The AI | Synthesized, source-cited pages the librarian writes and maintains. |
| `outputs/` | The AI | Reports and answers it generates on request. |

The rules that keep it honest - cite every claim, update don't append, never invent facts,
never reproduce secrets - live in [`CLAUDE.md`](CLAUDE.md).

## Quick start

1. **Get the files.** Click "Use this template" (or clone this repo) into a new folder.
2. **Open the folder as a vault in [Obsidian](https://obsidian.md).** Free. This is your
   reading and browsing surface.
3. **Point [Claude Code](https://claude.com/claude-code) at the folder.** It reads `CLAUDE.md`
   automatically and becomes your librarian. (Any coding agent that reads `CLAUDE.md`/`AGENTS.md`
   works; Claude Code is the reference.)
4. **Look at the `example-` pages** in `wiki/` to see the shape, then delete them.
5. **Drop your first sources into `raw/`** and run `/ingest`.

## The three commands

- `/ingest` - read new sources in `raw/` and fold them into the wiki.
- `/query` - ask a question; answered only from what's in the vault, with citations.
- `/lint` - monthly health audit; it proposes fixes, you approve them.

## A word on secrets

Personal notes often hold tokens, passwords, and one-time codes. The schema forbids the
librarian from ever copying a secret value into the wiki, and the included `.gitignore`
blocks the usual offenders. **Do not push your populated vault to a public remote until you
have run a secrets audit.** Keep real secrets in a secrets manager, not in the vault.

## Credit

The pattern is Andrej Karpathy's LLM Wiki / exocortex idea (April 2026). This repo is one
opinionated, ready-to-run implementation of it.

## License

MIT. Use it, fork it, sell services around it.

---

### Want it done for you?

Setting this up, importing years of scattered notes cleanly, and keeping it maintained is a
service I offer to consultants and small agencies through **Revenue With AI**. If your AI
should already know your clients, your SOPs, and every decision you have made - reach out:
Jason Wall, [revenuewithai.com](https://revenuewithai.com).
