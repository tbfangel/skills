---
name: diataxis
description: Structure and write technical documentation using the Diátaxis framework (Tutorials, How-To Guides, Reference, Explanation). Two modes — (1) initialise a repo's docs/ tree to adopt Diátaxis, including the top-level docs/README.md; (2) write a doc in the right quadrant, including deciding which of the four quadrants it belongs to. Inject when setting up docs, writing or categorising documentation.
---

# Diátaxis documentation

[Diátaxis](https://diataxis.fr/) organises documentation by **user need**, along two axes:
what the reader is doing (acquiring skill vs. applying it) and what they need (practical steps
vs. theoretical knowledge). This yields four quadrants:

```
                  PRACTICAL            THEORETICAL
                ┌──────────────┬──────────────────┐
   LEARNING     │  Tutorials   │   Explanation    │
   (acquiring)  │  learning-   │  understanding-  │
                │  oriented    │  oriented        │
                ├──────────────┼──────────────────┤
   WORKING      │  How-To      │   Reference      │
   (applying)   │  task-       │  information-    │
                │  oriented    │  oriented        │
                └──────────────┴──────────────────┘
```

Keep the four kinds separate. A document that tries to teach, instruct, specify, and explain
at once serves no one well. When content spans needs, **split it** and cross-link.

This skill has two modes:
- **Init** — set up a repo to adopt Diátaxis.
- **Write** — categorise and write a piece of documentation.

---

## Mode: Init

Use when a repo has no Diátaxis structure yet (or only an ad-hoc `docs/`).

1. **Find the docs root.** Usually `docs/` at the repo root. If the location is given by the
   invocation context, use that; otherwise default to `docs/`. Preserve any existing files.

2. **Create the four category directories**, each with a `README.md` overview:

   ```
   docs/
   ├── README.md            ← top-level docs landing page (see step 3)
   ├── tutorials/README.md   ← learning-oriented
   ├── how-to/README.md      ← task-oriented
   ├── reference/README.md   ← information-oriented
   └── explanation/
       ├── README.md         ← understanding-oriented
       └── design-decisions/README.md   ← ADR index (optional but recommended)
   ```

   Category `README.md` template (adapt the purpose line per category):

   ```markdown
   # <Category>

   <One-line description of what lives here.>

   ## Purpose

   <Category> documentation is **<orientation>-oriented**. It:
   - <trait 1>
   - <trait 2>
   - <trait 3>

   ## Contents

   *Nothing here yet.*

   ## Contributing

   <What to keep in mind when adding a doc to this category — see the Write mode below.>
   ```

   Orientation / purpose per category:
   - **tutorials** — *learning*-oriented: teach a newcomer through a hands-on lesson; success = they learned something.
   - **how-to** — *task*-oriented: help someone already competent accomplish a specific goal; success = the task is done.
   - **reference** — *information*-oriented: describe the machinery accurately for lookup; success = they found the fact.
   - **explanation** — *understanding*-oriented: discuss the "why", context, and trade-offs; success = they understand.

3. **Create or update the top-level `docs/README.md`** so the repo declares it follows
   Diátaxis and links the four categories:

   ```markdown
   # <Project> Documentation

   <One or two lines on what this documents.>

   ## Documentation Structure

   This documentation follows the [Diátaxis framework](https://diataxis.fr/), which organises
   technical documentation into four complementary categories based on user needs:

   - **[Tutorials](./tutorials/README.md)** — learning-oriented, hands-on lessons for newcomers
   - **[How-To Guides](./how-to/README.md)** — task-oriented steps to accomplish a specific goal
   - **[Reference](./reference/README.md)** — information-oriented technical specifications for lookup
   - **[Explanation](./explanation/README.md)** — understanding-oriented discussion of the "why"

   ## Quick Navigation

   - **New here?** Start with the [Tutorials](./tutorials/README.md).
   - **Need to get something done?** See the [How-To Guides](./how-to/README.md).
   - **Looking for technical details?** See the [Reference](./reference/README.md).
   - **Want to understand the "why"?** Read the [Explanation](./explanation/README.md).

   ## Contributing

   1. Put each new doc in the single category that matches the reader's need (see the four above).
   2. Name files in kebab-case (`setting-up-the-database.md`); `README.md` stays uppercase.
   3. Keep the categories distinct — split a doc that serves multiple needs and cross-link.
   ```

   If `docs/README.md` already exists, **merge** — add the *Documentation Structure* section
   and category links rather than overwriting existing content.

4. **Wire up the docs site nav if one exists.** If the repo uses MkDocs (`mkdocs.yml`),
   organise the top-level `nav` by category, each pointing at the category `README.md`. Only
   surface important pages; don't list every file (e.g. individual ADRs live in the
   design-decisions index, not the nav).

   ```yaml
   nav:
     - Home: README.md
     - Tutorials:
         - Overview: tutorials/README.md
     - How-To:
         - Overview: how-to/README.md
     - Reference:
         - Overview: reference/README.md
     - Explanation:
         - Overview: explanation/README.md
         - Design Decisions: explanation/design-decisions/README.md
   ```

5. **Report** the created/changed files. Don't invent placeholder content pages — empty
   categories with overview READMEs are the correct starting point.

---

## Mode: Write

### Step 1 — Choose the quadrant

Ask: **what does success look like for the reader?** Walk the decision tree top to bottom and
stop at the first match:

1. Teaching a newcomer a skill through a guided, hands-on lesson? → **Tutorial**
2. Helping a competent reader accomplish a specific real-world task? → **How-To Guide**
3. Providing factual technical information for lookup/consultation? → **Reference**
4. Explaining concepts, reasoning, or the "why" behind something? → **Explanation**

| Quadrant | Reader | Reader's goal | You are… | Litmus |
|----------|--------|---------------|----------|--------|
| Tutorial | newcomer | learn by doing | a teacher at the reader's side | "By the end you will have built X." |
| How-To | practitioner | get a task done | a knowledgeable colleague | "To achieve X, do these steps." |
| Reference | someone who knows what they want | look up a fact | a precise, neutral describer | "X accepts these parameters / returns this." |
| Explanation | someone curious about why | understand | a discussion partner | "X works this way because…; the alternative was…" |

**Spans multiple quadrants?** That's the common case — split it. E.g. a new API feature →
*Reference* for the spec, *How-To* for common tasks, *Explanation* for the design rationale,
and a *Tutorial* if it's part of a learning path. Don't force one document to do all four.

**Quick disambiguations:**
- *Tutorial vs How-To*: is the reader learning, or working? Learning → Tutorial; working → How-To.
- *Reference vs Explanation*: facts for lookup → Reference; reasoning and context → Explanation.
- *Troubleshooting* → usually How-To (problem → diagnosis → fix → verify).
- *A list of commands* → Reference if it's a comprehensive lookup; How-To if the commands accomplish a task; Tutorial if it's a teaching sequence.

### Step 2 — Write to the quadrant's shape

Match the conventions of whatever already exists in that category; otherwise use these shapes.

- **Tutorial** (learning-oriented)
  - State the concrete thing the reader will have built/achieved, and any prerequisites.
  - Number the steps; give complete, working, copy-pasteable examples.
  - Keep the reader succeeding — minimise choices and detours; explain just enough as you go.
  - End with what they accomplished and a "Next steps" pointer.
  - *Avoid*: options/alternatives, deep rationale, exhaustive specs (link to those instead).

- **How-To Guide** (task-oriented)
  - Open with the goal/problem statement and prerequisites/assumptions.
  - Numbered steps to achieve the goal; address realistic variations where needed.
  - Include verification ("you should now see…") and common-issue troubleshooting.
  - *Avoid*: teaching fundamentals, full specifications, design rationale.

- **Reference** (information-oriented)
  - Describe the machinery accurately and completely; structure like an encyclopedia entry.
  - Consistent formatting across similar items; neutral, terse, no editorialising.
  - Examples show *syntax/shape*, not usage scenarios; cover all options/params/errors.
  - *Avoid*: procedures, teaching, opinions about when to use it.

- **Explanation** (understanding-oriented)
  - Start with the problem space / context; discuss alternatives and trade-offs.
  - Explain the reasoning and connect it to broader principles; admit limitations.
  - No strict structure — adapt to the topic; discursive is fine.
  - *Avoid*: step-by-step instructions, exhaustive specs.

### Step 3 — Place, name, and link

- **Path**: `docs/<category>/<name>.md` (`explanation/design-decisions/` for ADRs).
- **Naming**: kebab-case (`getting-started.md`, `deploy-to-production.md`); `README.md` stays uppercase.
- **Index**: add the new doc to that category's `README.md` contents list (sorted/grouped to match the existing style).
- **Cross-link** generously across categories with relative links — e.g. a How-To links to the
  relevant Reference; an Explanation links to the hands-on Tutorial. Cross-linking is how the
  separated quadrants stay connected for the reader.

### ADRs

ADRs are a specific form of **Explanation**, living in `docs/explanation/design-decisions/`
(Michael Nygard format: Status, Context, Decision, Consequences; sequential numbering; once
accepted they're superseded rather than rewritten). For the full template, numbering, and index
workflow, use the **adr-writer** skill.

---

## Principles

- One document, one user need. When in doubt, ask "is the reader learning, working, looking
  something up, or trying to understand?"
- Better to categorise imperfectly than not document at all — content can be moved later.
- Each category gets a `README.md` overview; the top-level `docs/README.md` declares Diátaxis.
- Keep tutorials and how-tos free of long explanations; keep reference free of opinion; link instead.
