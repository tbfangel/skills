---
name: adr-writer
description: Provides the ADR template, numbering conventions, and placement for creating Architecture Decision Records. Inject when documenting architectural decisions, technology choices, or significant design changes. Works in any repo — the ADR location is normally given by the invocation context; if unknown, it is detected or asked for.
---

# Architecture Decision Records (ADRs)

An ADR captures the **why** behind a significant decision — the context, what was decided, and
the consequences. This skill is generic: it makes no assumption about where ADRs live in a
given project. Resolve the location first (Step 0), then write.

---

## Step 0 — Locate the ADR directory

The ADR location is usually **known from the invocation context** (a CLAUDE.md pointer, a
convention stated in the conversation, or an explicit path). Use that. Otherwise resolve it:

1. **Explicit location given** → use it.
2. **Detect an existing ADR directory** in the local repo. Look for a folder of numbered
   ADR files (`NNNN-*.md`) or an ADR index. Common locations, in order:
   - `docs/explanation/design-decisions/` — the [Diátaxis](https://diataxis.fr/) **Explanation**
     pillar (ADRs document the "why", so they belong here when a repo follows Diátaxis)
   - `docs/adr/`, `docs/adrs/`, `docs/architecture/decisions/`
   - `adr/` or `doc/adr/` at the repo root

   ```bash
   # Find existing ADRs / an ADR index anywhere in the repo
   find . -path ./node_modules -prune -o \
     \( -iregex '.*/[0-9][0-9][0-9][0-9][-.].*\.md' -o -ipath '*adr*' \) -print 2>/dev/null | grep -i -E 'adr|decision' | head
   ```
3. **No ADRs yet but the project follows Diátaxis** (a `docs/explanation/` tree exists) →
   create them under `docs/explanation/design-decisions/`.
4. **Ambiguous or not found** → ask the user where ADRs should live before creating anything.
   Do not guess a new location silently.

Call the resolved directory `ADR_DIR` below. Its index file is `ADR_DIR/README.md` (or the
existing index file the directory already uses — in an OKF bundle this is `ADR_DIR/index.md`).

---

## Step 0.5 — Detect OKF context

If the ADRs live inside an **OKF (Open Knowledge Format) bundle**, ADRs must be written as OKF
concept cards, not plain Markdown. Detect this before writing:

1. Look for an OKF bundle root at or above `ADR_DIR` — an `index.md` whose frontmatter declares
   `okf_version`:
   ```bash
   grep -rl --include=index.md "okf_version" . 2>/dev/null | head
   ```
2. If found, set **OKF mode** and locate the bundle's local schema — a `schema.md`, `CLAUDE.md`,
   or similar page describing the local `type` taxonomy and house style. **Read it; it is
   authoritative over the generic guidance here** (it may fix the `type` value, required tags,
   or a house card style).
3. In OKF mode, use the **OKF ADR card** format below instead of the plain template, and the
   bundle's reserved `index.md` is the ADR index (see [ADR Index Maintenance](#adr-index-maintenance)).

If there is no OKF bundle, use the plain ADR template as normal.

---

## ADR Template

```markdown
# [NNNN]. [TITLE]

## Status

[Proposed | Accepted | Deprecated | Superseded by [ADR-NNNN](link)]

## Context

[The problem being solved. Relevant constraints — technical, business, timeline.
Stakeholders affected. Related systems or decisions.]

## Decision

[What will be done. Specific and actionable — not "we might". Key implementation details,
technologies, or patterns chosen.]

## Consequences

[What becomes easier. What becomes harder. Risks and mitigation strategies.
Any technical debt introduced.]
```

### OKF ADR card (use in OKF mode — Step 0.5)

Wrap the same four sections in OKF frontmatter and a summary lead line. Only `type` is required
by OKF, but fill the recommended fields. Use the `type` value the local schema specifies for
decisions (e.g. `decision`); if the schema is silent, use `decision`.

```markdown
---
type: decision                                   # or whatever the local schema names decisions
title: NNNN. <Decision title>
description: <One-sentence statement of the decision>
tags: [decision, <topic tags per local schema>]
timestamp: <YYYY-MM-DD>                           # today, or the date the status last changed
---

# NNNN. <Decision title>

> <One-sentence statement of the decision — same text as `description`>

## Status
[Proposed | Accepted | Deprecated | Superseded by [NNNN](link)]

## Context
[As above.]

## Decision
[As above.]

## Consequences
[As above.]

## Related
- [Concepts and other ADRs this bears on](/path/to/card.md) — as plain Markdown links.
```

Notes for OKF mode:
- The ADR's four sections carry the substance, so a separate `## Key Facts` section is not
  required; `## Related` supplies the OKF cross-links.
- Keep `description` and the `>` lead line identical, and bump `timestamp` when the status changes.
- Preserve any extra frontmatter keys the local schema requires.

## Numbering

1. Read the existing ADR index (`ADR_DIR/README.md`) and list `ADR_DIR` for the highest number.
2. If the repo uses pull requests, check open PRs for ADRs that may already claim the next number:
   ```bash
   gh pr list --state open --json number,title,body | grep -i -E "ADR|[0-9]{4}-"
   ```
3. Use the next available 4-digit number not claimed by any existing ADR or open PR.
4. Format: `NNNN-decision-title.md`, kebab-case (e.g., `0003-select-postgresql-as-primary-database.md`).
   If the existing ADRs use a different numbering/naming style, match it.

## Content Quality Standards

**Context** — state the problem clearly, list constraints, name affected stakeholders, reference related decisions.

**Decision** — be specific; use active voice ("We will use X" not "X could be used"); include key implementation detail.

**Consequences** — list both positive and negative outcomes; identify risks with mitigations; note technical debt.

## Status Lifecycle

| Status | Meaning |
|--------|---------|
| Proposed | Under discussion, not yet accepted |
| Accepted | Decision made and in effect |
| Deprecated | No longer relevant; kept for history |
| Superseded | Replaced by a newer ADR — link to replacement |

Never delete deprecated or superseded ADRs — they provide historical context.

## ADR Index Maintenance

After creating a new ADR, add a row to the index (`ADR_DIR/README.md`, or `ADR_DIR/index.md`
in an OKF bundle — where it is the reserved navigation file, so omit `type`/`description` on it):

| ID | Title | Status |
|----|-------|--------|
| 0001 | ... | Accepted |

If the directory has no index yet, create one. Match the existing index format if there is one.

## Behavioural Principles

- Focus on the "why" — not just the "what"
- Use concrete details; avoid vague language
- Consider both positive and negative consequences
- Link related ADRs when applicable
- Keep ADRs readable in a few minutes
