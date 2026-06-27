---
name: okf
description: Read, query, and write an LLM wiki that conforms to the Open Knowledge Format (OKF). Inject when answering questions from a knowledge base, or when adding/updating/ingesting knowledge into one. Works with any OKF bundle — local (a docs/ or wiki/ folder) or remote (Notion, Obsidian, etc.); the wiki location is normally given by the context in which the skill is invoked.
---

# OKF — Open Knowledge Format wiki

A single skill for both **reading** and **writing** an LLM wiki that follows the
[Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)
(OKF, draft v0.1).

An OKF wiki is a tree of **concept cards** — Markdown files with YAML frontmatter. Each card
is a concise digest: what something is, a few key facts, and links to authoritative sources.
It is a navigation-and-synthesis layer, **not** a copy of the underlying documentation.

This skill is generic. It makes **no assumptions about where the wiki lives** — resolve the
location first (Step 0), then follow the Read or Write workflow.

---

## Step 0 — Locate the wiki

The wiki location is usually **known from the invocation context** (a CLAUDE.md pointer, the
repo you are in, an explicit path/URL, or a prior turn). Use that. Otherwise resolve it:

1. **Explicit location given** → use it. May be a directory, a repo, or a remote handle
   (Notion workspace/page, Obsidian vault path, etc.).
2. **Local OKF bundle in the current repo** → look for an OKF bundle root: an `index.md`
   whose frontmatter declares `okf_version`. Conventional roots, in order: `./`, `docs/`,
   `wiki/`. The directory containing that root `index.md` is the **bundle root** — the base
   for all paths below.

   ```bash
   # Find the OKF bundle root (the index.md that declares okf_version)
   grep -rl --include=index.md "okf_version" . 2>/dev/null | head
   ```
3. **Remote backend** (Notion, Obsidian, Confluence, a different git repo…) → use the matching
   access method: the relevant MCP server (e.g. Notion), file reads against a vault path, or
   `gh`/`git` for another repo. The OKF concept model still applies — frontmatter + body +
   Markdown links — even if the backend stores it differently.
4. **Ambiguous or not found** → ask the user where the wiki lives before proceeding. Do not
   guess and do not silently create a new wiki.

For a writable git-backed wiki, make sure your local copy is current (`git pull --ff-only`)
before editing, and stop if the pull fails.

Call the resolved base `WIKI` below.

---

## OKF format reference

**Concept card** — every non-reserved `.md` file. Required + recommended frontmatter:

```markdown
---
type: <short string for the kind of concept>   # REQUIRED, non-empty
title: <Human-readable display name>            # recommended
description: <One-sentence summary>             # recommended (mirror as the `>` lead line)
resource: <URI of the underlying asset>         # recommended, when one exists
tags: [<tag1>, <tag2>]                          # recommended
timestamp: <YYYY-MM-DD>                          # recommended; ISO 8601, last meaningful change
---

# <Title>

> <One-sentence summary — same text as `description`>

## Key Facts
- <2–5 bullets; never copied verbatim from the source>

## Links
- [Authoritative source](url) — <what you'll find there>

## Related
- [Related concept](/section/page.md)
```

Rules from the spec:

- **`type` is the only required field** and must be non-empty. All others are recommended.
  Recommended field order: `type`, `title`, `description`, `resource`, `tags`, `timestamp`.
- **Concept ID** = the file's path within the bundle minus `.md` (e.g. `services/iam.md` → `services/iam`).
- **Relationships are plain Markdown links.** Prefer **absolute** links (start with `/`,
  relative to the bundle root); relative links are also valid. The relationship type is
  carried by the surrounding prose, not the link.
- **Reserved files** — only `index.md` and `log.md` have special meaning:
  - `index.md` — a directory listing for navigation. NOT a concept: omit `type`/`description`.
  - `log.md` — chronological update history. Also not a concept.
  - The **bundle-root `index.md`** is the only place `okf_version: "0.1"` is declared.
- **Tolerance** — consumers must tolerate unknown frontmatter keys, unknown `type` values,
  missing optional fields, broken links, and absent `index.md` files. Never reject a bundle
  for these; preserve unknown keys when editing.
- A bundle may carry **extra custom frontmatter keys** beyond the above — keep them intact.

> A given wiki may layer its own conventions on top of OKF (a fixed `type` taxonomy, required
> `tags`, a digest-card house style). If the wiki has a CLAUDE.md / schema doc, read it and
> follow it — it is authoritative over the generic guidance here.

---

## Read / query workflow

1. **Locate** the wiki (Step 0).
2. **Search** for relevant cards — Grep/Glob across the bundle for keywords and likely
   filenames. Start at the bundle-root `index.md` and section `index.md` files when unsure
   where to look. For remote backends, use that backend's search.
3. **Read the digest cards** — Key Facts give the quick answer; read those first.
4. **Follow links for detail** when the digest is not enough:
   - Public URLs → WebFetch
   - GitHub files → `gh api "repos/<owner>/<repo>/contents/<path>" --jq '.content' | base64 -d`
   - Other systems → the matching MCP/tool
5. **Compose and cite** — state which wiki card(s) and/or authoritative source(s) the answer
   came from.

Important:
- Don't answer from memory alone when the wiki covers the topic — check it first.
- If no relevant card exists, say so; optionally offer to add one (Write workflow).
- If a card's `timestamp` is old, note the information may be stale.

---

## Write workflow

### Read the schema first
If the wiki has a CLAUDE.md or schema page, read it before writing — it defines the local
`type` taxonomy, naming, and house style. Do not skip this.

### Check for an existing card
Search the bundle before creating anything. **Update an existing card rather than duplicating.**

### Add a new concept card
1. Create the file at the correct path for its section/`type` (the path becomes its concept ID).
2. Use the concept-card format above. Set `type` (required) and, where they apply, `title`,
   `description`, `resource`, `tags`, and today's `timestamp`.
3. Keep it a **digest, not a copy**: 2–5 Key Facts in your own words, at least one
   authoritative Link, and `Related` cross-links to adjacent cards.
4. Update the section `index.md` — add a one-line, alphabetically-sorted entry.
5. If you created a new section, add it to the bundle-root `index.md` (which carries
   `okf_version`).

### Update an existing card
1. Change only what is new or wrong; preserve unknown/custom frontmatter keys.
2. Bump `timestamp` to today. If the summary changed, update both `description` and the
   `>` lead line so they still match.
3. Fix or extend Links and cross-references.

### Ingest a source (notes, PR, thread, article…)
1. If the wiki tracks ingested sources (e.g. a `sources/` log or `log.md`), check whether this
   source was already ingested — if so, treat it as an update pass.
2. Identify which concepts the source touches.
3. For each: find or create the card; update Key Facts and Links. **Summarise — never paste
   source content.**
4. Record the ingestion in the wiki's source log if it has one.
5. Update affected `index.md` files.

### Commit (git-backed wikis)
One focused commit per logical change; do not batch unrelated cards. Match the wiki's existing
commit convention if it has one (e.g. a `wiki:` prefix).

---

## Quality checklist (write)

- [ ] Wiki located and (if writable + git-backed) up to date
- [ ] Local schema/CLAUDE.md read and followed, if present
- [ ] No content copied verbatim from an external source
- [ ] `type` present and non-empty; recommended fields filled where they apply
- [ ] `description` matches the `>` lead line
- [ ] Key Facts ≤ 5 bullets
- [ ] At least one authoritative Link
- [ ] `timestamp` is today's date (for new/updated cards)
- [ ] Section `index.md` updated when a card was added/removed
- [ ] Cross-references added to related cards; unknown frontmatter keys preserved
