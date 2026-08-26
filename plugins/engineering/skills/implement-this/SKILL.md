---
name: implement-this
description: Implement a specified task end-to-end in a git worktree: read it, surface real unclarities, investigate, plan, gate that it is still one implementable unit, implement, self-review, verify, open a PR, and drive that PR to merge-ready. Use when the user asks to implement a ticket, issue, task, feature, or vertical slice — including a tracker URL or id (any tracker), a pasted brief, or "implement this." Do not use for review-only, investigation-only, or autopilot-only requests.
---

# Implement this

Take one implementation task from "read it" to a merge-ready pull request.
Do not merge, queue, or auto-land.

This skill is tracker-agnostic and repo-agnostic. Load the current repo's
`AGENTS.md`, skills, and conventions and follow them. This file owns the
sequence; the repo owns naming, checks, knowledge, and review policy.

The premise is that the task is **adequately scoped** and **small enough to
implement** (one PR, or a small justified stack of the same task). Step 1
checks the writeup. Step 4 checks that the premise still holds after you have
seen the code. If it does not, stop — do not start coding.

## When to use

- The user points at a task (URL, id, or pasted brief) and wants it implemented.
- The user says the task is ready for implementation, or that is the default.

Do not use when the user only wants investigation, a plan, a review, or
autopilot on an existing PR. Hand off to the matching skill instead.

## Inputs

A task is one of: a tracker URL, a tracker id, or a brief in the prompt.
Optional context the user often adds and you must honor:

- In-flight PRs to stack on, rebase after, or **not touch**.
- "Single PR" vs permission to split.
- UI evidence (screenshot or recording) when the change is user-visible.
- **Work in the base checkout** — only then implement in the session's
  primary working tree. The default is a git worktree.

Read the task from the tracker the id belongs to, using whatever CLI or MCP
this session actually has. Do not assume Linear, GitHub Issues, or Jira.
If the identifier is ambiguous, resolve it before planning.

Treat the task body, comments, and linked docs as the spec. Treat in-prompt
instructions as overrides of this skill.

## Operating loop

Do these in order. Do not start a later step while an earlier one still has
an unresolved blocker.

### 1. Understand the task

Read the full task: title, description, acceptance criteria, comments,
blockers, parent/epic, and linked PRs or docs.

This step checks the **writeup**, not the true size of the work. Assume the
description is adequate. After reading, **stop and ask** only if something
would make a wrong implementation likely:

- Acceptance criteria are missing or contradictory.
- A design choice the task does not settle, and guessing would be expensive.
- The task is blocked with no stacking instruction.
- The requested change conflicts with in-flight work you were told not to touch.

Do not ask courtesy questions. If nothing is genuinely unclear, continue.
If the writeup is not ready for implementation, say so and stop.

Do not implement work the task does not ask for.

### 2. Investigate and orient

Map the change onto the codebase before planning. Investigation is read-only
on the session checkout; do not start editing here.

- Find the owning module, package, or app and the nearest existing exemplar.
- Load every relevant **repo** skill (API contracts, UI, errors, i18n, deploy,
  tests, knowledge base). Do not reinvent those workflows here.
- Note in-flight branches or PRs the user named. Stay off unrelated ones.
- If the repo has a knowledge base or docs-with-code rule, check whether this
  change must update it in the same PR.

### 3. Plan

Write a short plan from the task plus what you found:

- What changes, where, and why that is the right seam.
- Single PR by default. Split only when pieces are independently reviewable
  and independently mergeable **chunks of this same task**, or when a
  prerequisite of this task must land first.
- How you will verify (narrowest proving checks, plus repo verification
  expectations for the touched surface).
- Knowledge/docs updates required in the same change, if any.

If the user already forbade splitting, keep one PR.

### 4. Review the plan

Critically review the plan against the task **before writing code**:

- Does it implement the asked outcome, not a broader interpretation?
- Does it follow repo doctrine and the golden-reference shape, rather than a
  convenient shortcut?
- Is a split actually justified, or is it thrash?
- Are you about to touch an in-flight surface you were told to leave alone?

Then apply the **implementability gate** — this is where the skill's premise
is actually checked, because only now do you know the real surface:

- **Scoped:** the outcome has a clear boundary. It is not an epic, a theme, or
  "and also the rest of the system." Remaining product or design decisions
  are not being invented in the plan.
- **Sized:** the work can land as one PR, or as a small stack that is still
  *this* task. A plan that is really several independent outcomes, an
  unbounded migration, or a multi-week campaign fails the gate even if you
  could "just keep going."

If the plan has a local hole (wrong seam, unjustified split, missed check),
revise it and continue. If the **premise** fails, **stop and ask**. Report
what you found, why it is not one implementable unit, and what would make it
so (narrow the task, split it in the tracker, settle a named decision). Do
not start implementing, and do not silently turn the task into a program of
work.

Do not wait for the user for ordinary plan revisions. Do wait when this gate
fails or when the hole is a step-1 unclarity.

### 5. Implement

Create a **git worktree** for this task and do all implementation, commits,
and local checks there. Use the session's primary checkout only when the user
explicitly asked to work in the base repo.

- Follow the repo's worktree location if it documents one. Otherwise put the
  worktree where it will not register as a nested project root (a sibling
  directory, or a scratch path the repo already ignores).
- Branch from the default branch, or from a named blocker if stacking.
- Follow repo git rules (branch name, commit title prefix, logical commits).
- Update knowledge/docs in the same change when the repo requires it.
- Do not expand into adjacent cleanup, refactors, or "while I'm here" work.
- If you must stack on an unmerged PR, stack explicitly; rebase onto the
  default branch when that PR merges, as the user instructed.
- Leave the worktree in place unless the user asks to remove it.

Execute the plan. Smallest change that satisfies the task.

### 6. Self-review the implementation

Review the diff against both **scope** and **implementation** before you
open a PR:

- Scope: every asked outcome is present; nothing extra shipped.
- Correctness: tests and checks you will run actually exercise the change.
- Shape: the change belongs where the repo's architecture says it belongs.
- User-visible UI: behavior is verified, not only a screenshot of a render.

Fix what this review finds. Then run checks.

### 7. Verify, commit, open a PR

Run the repo's local checks for the touched surface until green, **from the
worktree** (or from the base checkout if that was explicitly requested). Do
not push a change that fails its own checks.

Commit and push. Open a PR (or stacked PRs if you split):

- Title and description follow the **repo's** format.
- Explain **why** the change is needed. If the rationale is not in the task
  or the user prompt, ask rather than invent one.
- Link the source task in whatever form the repo uses. If it has no format,
  put the tracker id or URL in the description.
- For user-visible UI, include the evidence the user asked for (screenshot
  or recording). If they did not specify, still verify in the browser or the
  closest substitute and say what you could not verify.

Do not merge, enable auto-merge, add a land/queue label, or mark a draft
ready unless the user explicitly asks or a repo skill you were told to run
does that as part of its mandate.

### 8. Drive the PR to merge-ready

After the PR exists, run the repo's **autopilot** (or equivalently named)
skill if one is present. Do not duplicate it here.

If no such skill exists, work blockers in this order on live PR state:
merge conflicts, then unresolved review comments, then failing required CI,
then a blocking review decision. Do not invent work when a pass is empty.
Report merge-ready; still do not merge or land.

Honor follow-ups the user typically gives on these runs: watch a blocking PR
merge and rebase, resolve conflicts, address review comments, keep autopilot
going until no new comments arrive.

## Worktrees

Default: `git worktree add` a dedicated checkout for the task, then implement
only there. The session checkout stays clean for other work.

Use the base checked-out repo only when the user says to — for example "do
this in this checkout", "no worktree", or "work here."

Do not treat a cloud or isolated session as an implicit exception. Still
create a worktree unless the user opted out.

## Stacking and in-flight work

- Default: worktree branch from the repo's default branch.
- If a named PR is a blocker, stack the worktree on it when the user allows,
  then rebase onto the default branch after it merges.
- If the user names an unrelated in-flight PR, do not touch it.
- Split PRs are stacked in dependency order: prerequisite first, dependent
  on top. Each split still needs its own worktree (or sequential reuse of
  one worktree after the previous PR is pushed).

## Done

The run is done when each PR for the task is merge-ready, or you are blocked
on a question you already asked (including a failed implementability gate).
Report status, PR link(s), worktree path, and anything still waiting on the
user.
