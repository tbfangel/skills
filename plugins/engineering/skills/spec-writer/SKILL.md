---
name: spec-writer
description: Interview-driven specification writing — relentlessly interrogates a feature until it is crystal clear, then writes an implementable spec (OKF-aware). Inject when writing a spec, scoping or spec'ing a feature before implementation, or turning a feature idea or request into an implementable contract. Assumes the project's technical doctrine (tech stack, architecture, design system, existing specs/ADRs/concepts) is available in the context and grounds the spec in it.
---

# Spec writer

A specification is the **contract code is built from**: it describes *what* a feature does and
*why*, and its observable behavior — not the internal implementation, which the code owns. This
skill's core is not the writing; it is the **interview**. Do not write a spec until the feature
is crystal clear. A vague spec is worse than none, because code will be built from it.

Resolve where specs live (Step 0), detect OKF context (Step 0.5), **interview relentlessly**
(the heart of this skill), then write.

---

## Step 0 — Locate the specs directory

Usually **known from the invocation context** (a CLAUDE.md pointer, a stated convention, or an
explicit path). Otherwise resolve it:

1. **Explicit location given** → use it.
2. **Detect an existing specs directory** — a folder of numbered spec files (`NNNN-*.md`) or a
   specs index. Common: `docs/specs/`, `specs/`, `docs/specifications/`.
3. **None yet** → ask the user where specs should live before creating anything. Do not guess a
   new location silently.

Call the resolved directory `SPEC_DIR`. Its index is `SPEC_DIR/index.md` (OKF bundle) or
`SPEC_DIR/README.md`.

## Step 0.5 — Detect OKF context and read the doctrine

1. **OKF bundle?** Look for a bundle root — an `index.md` declaring `okf_version`:
   ```bash
   grep -rl --include=index.md "okf_version" . 2>/dev/null | head
   ```
   If found, set **OKF mode**: the spec is written as a `type: spec` OKF card, and the bundle's
   reserved `index.md` is the spec index.
2. **Read the local conventions.** Look for a spec-conventions / house-style card (e.g.
   `SPEC_DIR/conventions.md`) and a bundle `schema.md`/`CLAUDE.md`. **Read them; they are
   authoritative** over the generic template below (they may fix the template, `type`, required
   tags, or numbering).
3. **Absorb the project doctrine.** This skill assumes the technical side is already established
   in the context — tech stack, architecture, design system, coding standards, and the existing
   `concepts/`, `decisions/` (ADRs), and prior specs. **Read what is relevant and ground the spec
   in it.** Do not re-derive or re-interview the technical doctrine; interview around the *feature*
   and the gaps the doctrine does not answer. When a spec would contradict an ADR, the ADR wins —
   surface the conflict rather than spec'ing around it.

---

## The interview — the heart of this skill

**Interview the user relentlessly until every dimension below is unambiguous.** Ground every
question in the doctrine from Step 0.5 so you ask about genuine unknowns, not things already
decided. Work in **small focused batches** (a few sharp questions at a time, not a wall), and
after each round **restate your current understanding** so the user can correct it. Prefer the
project's `AskUserQuestion`-style prompts for decisions with discrete options; use prose for
open ones.

Interrogate, at minimum:

- **Actor & trigger** — who (or what system) initiates this, and on what event?
- **Goal & value** — what job does it do for them; why is it worth building now?
- **Main path** — the primary flow, step by step, in observable terms.
- **Edge cases & failure modes** — empty/invalid/duplicate input, permissions, partial failure,
  concurrency, limits. *Push here hardest — this is where specs are usually vague.*
- **Data & interfaces** — the shapes introduced or consumed; API/contract surface; what other
  specs or systems it depends on. (Shape and contract — not internal implementation.)
- **Boundaries** — what is explicitly **out of scope**, and what is deferred to a later spec?
- **Non-functional constraints** — performance, scale, privacy, security, cost — only where they
  actually bind this feature.
- **Acceptance** — how will we know it is correctly built? Drive toward criteria that are each
  **objectively true or false**.

Rules of the interview:

- **Do not accept vagueness.** If an answer is fuzzy ("it should be fast", "handle errors
  gracefully"), ask again until it is concrete and testable.
- **Surface hidden assumptions** and get them confirmed or denied explicitly.
- **Force decisions on open questions.** A spec should not ship riddled with unknowns that block
  behavior. If an unknown is a genuine architectural fork, **promote it to an ADR** (via the
  `adr-writer` skill) rather than burying it in the spec.
- **One source of truth per fact** — if the doctrine already answers something, cite it; don't
  re-litigate.

**Stop interviewing only when:** the main path and its edges are enumerated, every acceptance
criterion is objectively checkable, the data/interface contracts are pinned, scope boundaries are
explicit, and no remaining open question blocks implementation. Then, and only then, write.

---

## Spec template

Match the bundle's local conventions card if one exists. Otherwise use this (the format from a
typical OKF `docs/specs/conventions.md`):

```markdown
---
type: spec
title: NNNN. <Title>
description: <One-sentence statement of what this spec defines>
tags: [spec, <topic tags per local schema>]
timestamp: <YYYY-MM-DD>
---

# NNNN. <Title>

> <One-sentence statement of what this spec defines — same text as `description`>

## Status
Draft | Ready | Implemented | Superseded by [NNNN](link)

## Context & goal
What this enables and why now. Link the concepts it implements and the ADRs that constrain it.

## Behavior
The observable behavior — user-facing flow and/or system behavior. Concrete, not vague.
Cover the main path and the notable edge cases.

## Data & interfaces
The data shapes, API surface, or contracts this introduces or depends on. Only what
callers/other specs need to know — not internal implementation.

## Acceptance criteria
A checklist that is objectively true or false when the spec is correctly implemented.

## Out of scope
What this spec deliberately does not cover (often a pointer to a future spec).

## Open questions
Unresolved decisions. Promote the significant ones to an ADR rather than settling them here.

## Related
Concepts and ADRs this spec touches, as plain Markdown links.
```

In **plain (non-OKF) mode**, drop the frontmatter and `>` lead line; keep the sections.

## Numbering

1. Read the spec index and list `SPEC_DIR` for the highest number.
2. If the repo uses PRs, check open ones for a spec that may already claim the next number:
   ```bash
   gh pr list --state open --json number,title,body | grep -i -E "spec|[0-9]{4}-"
   ```
3. Use the next available 4-digit number. Format: `NNNN-kebab-title.md`. Numbers are permanent.
   Match the existing naming style if there is one.

## Status lifecycle

| Status | Meaning |
|--------|---------|
| Draft | Being interviewed/written; thin and provisional. Keep early specs here. |
| Ready | Interview complete, crystal clear, safe to implement from. |
| Implemented | Built; the code now honors this spec. |
| Superseded | Replaced by a newer spec — link to it. |

Only promote `Draft` → `Ready` when the "stop interviewing" bar above is met.

## Index maintenance

After creating a spec, add a row to the index (`SPEC_DIR/index.md` in an OKF bundle — the
reserved nav file, so omit `type`/`description` on it; else `SPEC_DIR/README.md`):

| ID | Title | Status |
|----|-------|--------|
| 0001 | ... | Draft |

## Verify the draft — read it as the implementer

Writing the spec is not the last step. Once it is written, **read the whole thing back as if you
were about to implement it with no other context**, and hunt for anything that would block or
mislead you:

- **Every acceptance criterion** — is it objectively true/false, and could you write its test
  right now? If a criterion needs a value, name, or shape the spec does not give, it is
  underspecified — fix it.
- **The contracts** — are field names, headers, status codes, error shapes, defaults, and units
  all pinned? An implementer should never have to guess a name or invent a shape.
- **Hand-wavy claims** — flag anything you'd have to interpret, or any "X does Y" that X does not
  actually do (e.g. a tool that doesn't generate what you claimed). Correct it to what is real,
  and name the real dependency.
- **Implicit forks** — a decision the spec silently assumes (versioning, base paths, strict vs
  loose modes) should be stated outright, or promoted to an ADR.
- **Over-specification** — settled tech choices that belong in an ADR, not the behavioral
  contract; move them out and cite the ADR.

Fix what you find; surface it to the user when it is a genuine decision. Only a draft that
survives this cold read-through is ready to hand to an implementer.

## Behavioural principles

- **Interview until crystal clear** — the writing is the easy part; the clarity is the work.
- Specify **observable behavior, not implementation** — the code owns the how.
- Every **acceptance criterion is objectively true or false**.
- **Ground in the doctrine**; don't re-derive the tech stack or re-litigate settled decisions.
- **Promote architectural forks to ADRs**; keep the spec a digest, readable in a few minutes.
- When a spec and an ADR conflict, the **ADR wins** until a superseding ADR changes it.
- **Verify by reading as the implementer** — after writing, read the spec back cold and fix every
  place you would have to guess.
