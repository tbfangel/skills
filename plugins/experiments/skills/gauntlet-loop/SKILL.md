---
name: gauntlet-loop
description: Set up and run a Gauntlet Loop — a long-running multi-agent build where a lead agent splits the goal into independently judgeable pieces, each piece gets a builder plus a separate critic with fresh context, and every round is compared blind against a concrete reference bar until the output wins or the user stops it. Inject when the user asks for a gauntlet loop, wants an ambitious artifact (a game, site, demo, or document) built to beat a named reference, or asks to benchmark generated work against a real product and keep iterating.
---

# Gauntlet Loop

A Gauntlet Loop is a way of running a long, ambitious build so it does not stop at "good for
AI". The method is Matt Shumer's, described in
[How to Run a Gauntlet Loop](https://somethingbig.ai/gauntlet-loop) and demonstrated by
[Claude of Duty](https://github.com/mshumer/Claude-of-Duty) — a Call of Duty-style FPS built from
one prompt.

The shape of it:

1. A **lead agent** gets a goal and a **bar** — a concrete artifact it can inspect and lose to.
2. The lead splits the goal into the **smallest pieces that can be improved and judged
   separately**, and chooses the approach itself.
3. Each piece gets a **builder** and a **separate critic with fresh context**.
4. The critic inspects the **real output** — pixels, running build, rendered page, test results —
   compares it with the bar (blind A/B where possible), and if ours loses, names the single
   biggest gap and sends it back.
5. **Repeat with no fixed round count**, until our output wins or the user stops the run.

Two rules carry most of the value: **the bar must be something the agent cannot argue with**, and
**the builder never grades its own work**.

This skill has two jobs, in order: **interview the user until nothing is unclear** (Step 1 — the
heart of it), then **write and launch the run prompt** (Steps 2-4).

---

## Step 0 — Check the harness

A Gauntlet Loop needs an agentic harness that can open files, run code, render output, look at
screenshots, and spawn subagents. Claude Code or Codex — not a plain chat.

Before interviewing, establish:

- **Where the work happens.** A fresh directory or repo for the artifact. Ask if it is not obvious;
  never start a many-hour run inside an unrelated repo without saying so.
- **Effort.** Recommend `/effort` → ultracode for a serious run, and say plainly that it costs
  much more. It is the user's call.
- **The user's own capabilities.** Subagents with independent context windows are what make the
  critics honest. If the harness cannot spawn them, say so before starting — the loop degrades
  into self-review, which is the failure mode the method exists to prevent.

---

## Step 1 — Interview the user until nothing is unclear

**Do not write the run prompt until every question below is answered concretely.** A Gauntlet Loop
burns hours of compute against whatever bar it was given; a vague bar produces hours of confident
work aimed at nothing.

Work in **small focused batches** — a few sharp questions at a time, not a wall — and after each
round **restate your current understanding** so the user can correct it. Use `AskUserQuestion` for
choices with discrete options, prose for open ones.

### 1. What are we creating?

- What is the artifact — a game, a site, a tool, a document, a campaign? What does someone *do*
  with it?
- What platform and form factor? (Browser tab, desktop app, mobile, static page, repo.)
- Single-player or multiplayer, static or live, online or offline?
- Is there existing code or is this from zero?

Push until you could describe the finished thing in two sentences and the user would agree.

### 2. What is the bar?

The most important answer in the interview. **"Make it amazing" is not a bar.** The bar is a
specific artifact a critic can open, look at, and lose to.

Ask directly: **which existing game (or site, product, or piece of writing) is the benchmark?**

Then pin it down — a title alone is not yet usable:

- **Which one specifically?** Not "a shooter" — which game, which year, which mode.
- **What exact reference material do we compare against, and where does it come from?** Screenshots,
  a gameplay video, a live URL, a local build, a test suite, a latency number, a set of
  paragraphs. The critic must be able to *inspect* it every round.
- **Which dimensions count?** Visual fidelity, feel and responsiveness, audio, level design, UI
  polish, performance. A game bar is usually mostly visual; a backend bar is usually tests,
  latency, and failure recovery.
- **Which dimensions explicitly do not count?** Content volume, licensed assets, budget-scale
  scope, and anything the user does not care about — say so, so the critic does not chase it.

If the user has no reference in mind, **do not let the agent invent its own definition of "good"
at runtime.** Propose two or three concrete comps, explain in one sentence why each is a useful
bar, and get the user to pick.

**Then ask the question that decides whether one bar is enough: does the named benchmark actually
cover the piece the user cares most about?** Very often it does not, and this is the most valuable
catch available in the whole interview. Users pick a benchmark for the *category* — a runner, a
docs site, a CRM — but they are building it because of something the benchmark does not have.
A Subway Surfers-style runner whose edge is escalating fart weapons has no fart in its benchmark.
A docs site whose edge is a live API playground has no playground in the site it was compared to.

That piece is then the only one running with no bar, and its critics fall back on taste — the
exact failure the method exists to prevent, occurring in the piece that matters most.

So: walk the pieces the user named as the edge and check each against the benchmark. **Any piece
the benchmark cannot judge needs its own bar and its own critics**, sourced the same way — a
concrete artifact, named dimensions, inspectable every round. Two or three bars covering different
pieces is normal and correct; one bar with a hole in it is not.

**The bar does not need to be reachable.** Losing to a AAA title every round is the point — it
keeps the loop from stopping at "pretty good". Say this out loud if the user worries the bar is
unrealistic.

### 3. What are the goals?

- What does "done enough to stop" look like? Name it in observable terms.
- Which pieces matter most — where should the compute go first?

  **When the user has no scope target** — "just run until the budget is gone" — this stops being
  nice to know and becomes the only thing steering the run. A lead agent told to work whatever is
  weakest will spread compute evenly across the pieces, which is wrong whenever the user has an
  edge they care about: the weakest piece and the piece that matters are rarely the same one.
  Get an explicit priority order and write it into the prompt.
- Any hard constraints: performance budget, target hardware, dependency limits, licensing,
  file size, offline requirement, browser support?
- Anything explicitly **out of scope**?
- How long may the run go, and how much compute is the user willing to spend?
- How do they want to watch it — a live HTML progress page, a `workbench.md`, or both?

### Rules of the interview

- **Do not accept vagueness.** "Make it look good", "AAA quality", "fast" — ask again until the
  answer names something inspectable.
- **Do not fill gaps silently.** If the user shrugs at a question, propose concrete options and
  have them choose. An assumption you make here becomes the standard for hours of unattended work.
- **Keep asking until nothing is unclear.** When you believe you are done, restate the goal, the
  bar, the reference material, the priorities, and the stop condition, and ask outright whether
  anything is wrong or missing. Only after an explicit yes do you write the prompt.
- **Say when something cannot be done.** No reference material available, no way to render the
  artifact, no subagents — surface it now, not three hours in.

---

## Step 2 — Confirm the run plan

Restate, in one short block:

| | |
|---|---|
| **Goal** | What is being built, in one or two sentences. |
| **Bar** | The named reference and the exact material the critic will compare against. |
| **Judged on** | The dimensions that count — and the ones that do not. |
| **Constraints** | Hard limits and out-of-scope items. |
| **Stop condition** | What "ready" means, plus the time/compute ceiling. |
| **Progress view** | Live HTML page, `workbench.md`, or both. |

Get an explicit go-ahead before launching. This is the last cheap moment to change direction.

---

## Step 2.5 — Two gates before the loop starts

Both of these happen *inside* the run, before any critic is spawned, and both belong in the
prompt. They exist because a Gauntlet Loop fails quietly: the critics still run, still produce
confident verdicts, and are simply judging the wrong thing for eight hours.

### Gate 1 — Make the output inspectable

A critic must inspect the real artifact, which means the lead agent's **first build task is
whatever makes the artifact inspectable at all** — before any piece is judged.

For anything whose quality lives in motion or interaction — a game, an animation, a UI, a
gesture-driven app — a screenshot cannot carry it. Speed, responsiveness, input latency, and
readability-at-pace are invisible in a still frame. So the run needs a **capture harness**: the
lead agent must be able to record our own output the same way the reference is recorded, and hand
a critic *our clip against their clip*. Without it, critics silently downgrade to judging a still
life of a moving thing, and every verdict after that is about the wrong artifact.

The equivalent elsewhere: a rendered build and a screenshot pipeline for a site, a running test
harness with real output for backend work, a way to render finished prose as the reader will see
it for writing. State the requirement in the prompt as a prerequisite, not a suggestion.

### Gate 2 — Confirm the reference set with the user

When the agent sources its own reference material — as it must whenever the user cannot supply it
— **the run stops after collecting it and waits for the user to confirm.**

This is the highest-leverage checkpoint in the whole method. The reference set is chosen once, in
the run's first twenty minutes, and then governs every critic in every round for the rest of it.
A weak, unrepresentative, or off-target reference does not announce itself; it just quietly
becomes the standard, and the user discovers it hours later in the finished artifact.

Write into the prompt that the lead agent must present what it collected — the actual files, what
each one is a bar for, and why it chose them — then **stop and wait** before spawning any builder
or critic. When the user is asleep or away for a long unattended run, say so plainly during the
interview: either they seed the references before launching, or the run will sit at this gate
until they return. That is the trade, and it is theirs to make.

---

## Step 3 — Write the run prompt

**Keep it short.** The prompt states the goal, the bars, and the loop mechanics. It does **not**
prescribe architecture, the decomposition, the tech choices beyond real constraints, or a number
of rounds — those are the lead agent's to decide, and prescribing them replaces its judgment with
yours.

A thorough interview will surface more constraints than "keep it short" comfortably holds, so the
test for what survives into the prompt is: **does this protect the loop's mechanics, or is it a
choice the agent could make itself?** The bars, the gates, the priority order, the judged and
ignored dimensions, and the stop condition all protect the mechanics and go in. Architecture,
decomposition, libraries, and round counts are the agent's, and stay out. When a constraint is
genuinely load-bearing — a frame budget, a licence boundary, a target device — it is a constraint,
not an implementation choice, and it goes in too.

Template — fill the brackets from the interview, delete nothing else:

```
Build [WHAT], [PLATFORM/HARD CONSTRAINTS].

The bars — [PIECE OR ASPECT] is judged against [NAMED REFERENCE], on [DIMENSIONS THAT COUNT].
[Repeat for each piece the first bar cannot judge — the crux feature usually needs its own.]
Ignore [DIMENSIONS THAT DO NOT COUNT].

[PIECE] is the edge and gets first claim on compute. Work the rest only when it is what is
losing hardest.

First, assemble reference/ — [WHAT MATERIAL, FROM WHERE] — then show me what you collected, what
each item is a bar for, and why you chose it, and wait for my confirmation before spawning any
builder or critic.

Then build [THE CAPTURE HARNESS / RENDER PIPELINE / TEST RIG] so our own output can be recorded
and compared the same way the reference is. Critics compare ours against theirs directly; a critic
judging [A SCREENSHOT OF A MOVING THING / A SUMMARY] is judging the wrong artifact.

Then decide the approach yourself. Split the goal into the smallest pieces that can be improved
and judged independently. For each important piece, fan out a builder and a separate critic with
fresh context.

Each critic inspects the real output — not a summary from the builder — compares it directly
against its bar (blind A/B where possible), and if ours loses, names the single biggest remaining
gap and sends it back for another round. Keep looping until ours wins or I stop the run.

After each major wave, spawn one fresh agent to inspect the whole result and smooth out
inconsistencies between separately improved pieces.

Maintain a [live HTML progress page / workbench.md] showing the work evolving over time —
screenshots, builds, test results, whatever fits.

Use subagents and ultracode. Do not stop at a fixed number of rounds.
```

Show the prompt to the user before running it. Then launch it in the harness and leave it alone.

---

## Step 4 — Run and supervise

- **Do not steer mid-run.** The loop's value comes from uninterrupted iteration. Read the progress
  page instead of interrupting.
- **Watch for the loop dissolving.** The characteristic failures: a critic grading the builder's
  description rather than the artifact; a builder and critic sharing context; the bar quietly
  softening into self-assessment; rounds that stop naming a concrete gap; critics judging stills
  of something whose quality is in motion; a piece being worked that nobody has a bar for. If any
  appear, restate the loop rules to the lead agent — do not take over the work yourself.
- **Stopping is the user's call.** Offer to stop when improvements get small or the budget is
  reached; report honestly which pieces are strong and which are still losing to the bar.
- **Report what actually happened.** Rounds completed per piece, what the critics kept flagging,
  where the output still loses. Never describe the result as matching the bar unless a critic
  comparing the real output said so.

---

## Behavioural principles

- **The bar is the whole method.** No concrete reference, no Gauntlet Loop — just an expensive
  agent run.
- **Goal, not implementation.** Give the destination; let the agent choose the route.
- **The builder never grades itself.** Independent context is what makes the judgment worth having.
- **Critics inspect the artifact, never a summary of it.** Building the means to inspect it comes
  before the first judgment, not after.
- **Every piece under the loop has a bar.** A piece the benchmark cannot judge gets its own bar,
  or it is not in the loop at all — it is just being built and admired.
- **The reference set is confirmed before the loop starts.** It is chosen once and governs every
  round after.
- **Smallest judgeable pieces.** "Make the game better" is not attackable; "make this tree beat the
  tree in this screenshot" is.
- **No arbitrary final round.** Stop on quality or budget, never on a round count.
