---
name: open-work-review
description: >
  Review one person's whole trail of open work in Linear and GitHub: every open issue they are
  assigned or created, matched against their pull requests. It finds what is finished but still
  open, what is stale, what each top-level issue still needs before it can close, and what to
  focus on next, weighted by the priorities the person names. Ad hoc, it can clean up with
  approval and triage stale issues against the code. Scheduled, it is read-only and posts a weekly
  status to a Slack channel. Use when the user asks for "an overview of my open work", "my open
  issues", "my trail", "clean up my Linear", "what am I missing to close my epics", "what should I
  focus on", or a "weekly status".
---

# Open Work Review

The daily summary covers what moved yesterday. This covers everything still open, however old.
Open issues pile up: follow-ups filed mid-task, issues whose PR merged without closing them,
duplicates from a retried create, and epics whose last child closed weeks ago. The review
answers three questions:
1. What is open and in what state?
2. What does each stream still need before it can close?
3. Where should the person's effort go?

## Parameters

- **Mode** (`mode`): `interactive` (default when someone is in the chat) or `scheduled` (always
  when run as an automation).
  - **Scheduled is read-only.** It never writes to Linear or GitHub. Close candidates and
    re-scopes are listed as suggestions for the next interactive run.
- **Slack channel** (`slack_channel`): channel ID or URL
  (`https://<workspace>.slack.com/archives/<ID>` → `<ID>`). Interactive mode posts there only
  when one is given. Scheduled mode requires it; if it is missing, stop and say so.
- **Priorities** (`priorities`): optional. The streams, issues, or topics the person says matter
  most right now, e.g. "the notes for the financial statement", "the adjustments Task". In
  scheduled mode they come from the automation's prompt. Without priorities, skip that section
  and base the focus on the data alone.
- **Depth** (`depth`): `overview` (default) or `triage`. Triage checks every stale issue against
  the code with subagents. It is token-heavy, so it runs only in interactive mode and only when
  asked.
- **Linear team** (`linear_team`): optional. Defaults to every team the person belongs to.

The person is whoever is authenticated: `gh api user -q .login` for GitHub, `linear auth status`
(`.user.id`, `.user.email`) or the Linear MCP `get_user` with `me` for Linear. Do not ask for
these.

Keep intermediate JSON and scripts in the scratchpad directory, never in a repository.

## Tools

Prefer the `gh` and `linear` (linearis) CLIs. If either is missing or unauthenticated, which is
common in cloud automations, use the GitHub and Linear MCP tools for the same queries. If a source
is unreachable by both routes, say so in the output instead of leaving its section out.

linearis quirks that change results:
- **`--assignee` does not filter reliably.** Fetch all open issues and filter on `assignee.id`
  yourself. `--creator <email>` does filter.
- `--status` requires `--team`. List one status at a time (`Backlog`, `Todo`, `In Progress`,
  `In Review`), skip any name the team lacks, and page with `--after <endCursor>` until
  `hasNextPage` is false. Unscoped lists fail with "Query too complex".
- `issues list` returns no `creator` and no comments. `issues read <id>` returns comments,
  `children`, `relations` and `inverseRelations`, but not the children's states. Read each child
  for that.
- A `--duplicate-of` relation does not by itself move the issue to a closed state. Set the status
  too, then read the issue back.

## 1. Gather

**Issues.** Collect every open issue in the team(s). Keep those that are assigned to the person
or appear in the `--creator` lists of the same states.
- Report the two groups apart: *assigned* is their active load; *created, unassigned* is the
  trail.
- **Blind spot:** an issue an agent filed for them and left unassigned has the agent account as
  creator, so it is missed. Say so once in the output.

**Pull requests.** Fetch the repository's PRs once, not per issue:

```bash
gh pr list --repo <owner/repo> --state all --limit 10000 \
  --json number,state,isDraft,headRefName,title,body,mergedAt,updatedAt,author
```

Check the result reached the oldest PR. A `--limit` below the PR count silently drops the oldest
merges, which are the ones most likely to close a forgotten issue. Use every repository the
person's PRs live in.

**Link PRs to issues by strength:**
- **Strong:** the branch name carries the issue ID (`feat/rep-1740-…`), or the PR body's
  `### Task` section names it.
- **Weak:** the ID appears anywhere else in the title or body. Follow-ups and parents get
  mentioned all the time, so a weak link is never evidence that an issue is done.

Branches from some agents (`cursor/…`) carry no issue ID, so they only link through the Task
section. That is the most common reason a merged PR leaves its issue open.

## 2. Classify

Put each issue in the first bucket that fits:

| Bucket | Rule |
|---|---|
| **Wrapped up** | Has children, and every child is closed |
| **Delivered** | A strong-linked PR is merged and none is open |
| **In review** | A strong-linked PR is open (note draft/ready and days idle) |
| **Epic** | Has open children |
| **Blocked** | An open issue blocks it |
| **Started, no PR** | `In Progress` with no strong-linked PR |
| **Stale** | No update for 14+ days |
| **Recent** | Everything else |

Also flag across buckets:
- **Duplicates:** same title, created within minutes of each other (a retried create). Keep the
  one with the richest description or the merged PR.
- **Abandoned:** strong-linked PRs that were all closed unmerged.

## 3. Verify the close candidates

A bucket is a hint, not a verdict. Before listing anything as closable:
- **Delivered:** the merged PR's Task section or branch names this issue, and the PR delivers
  the issue's own scope, not one step of it. Re-read the issue: one blocked by open issues, or
  whose PR "records a proposed plan", may legitimately stay open.
- **Wrapped up:** read every child's state.
  - Canceled children are not delivered work.
  - Read the parent's description too. A parent may carry its own scope ("add a stable route
    for…") or say it is postponed. Check that scope on the default branch (`origin/<branch>`,
    never a possibly stale local checkout) before calling it done.
- **Duplicate:** compare the descriptions, not just the titles.

**Closing cascades.** Closing a child can leave its parent with no open children (REP-1470 →
REP-1454 → REP-1466). After each close, re-check the parent, and repeat until nothing more
closes.

## 4. Streams

Group the open issues and PRs by **top-level issue**. Follow `parent` until an issue has none
(`issues read`: `.parent`; Linear MCP `get_issue`: `parentId`), and cache every lookup. An issue
with no parent and no children goes under **Standalone**.

For each stream, record:
- The open children (count and states), with the `In Progress` ones named.
- The open PRs, with draft/ready, days idle, CI, and unresolved review threads.
- **What is missing to close it.** Name the remaining children and sort them into three kinds:
  - *decisions*: "Decide …", "Investigate …", "Discover …", or anything waiting on a PO,
    auditor, or designer answer;
  - *build* items;
  - *external waits*: a vendor, a sales approval, or test data that doesn't exist yet. Read the
    latest comments to tell which.
- **Unowned items on the critical path:** unassigned issues that block the person's own work.
- **Wrong premises:** an issue whose description contradicts a later decision recorded in a
  comment, a decision card, or the person's own statement.

## 5. Priorities

For each named priority, find its stream(s) and read beyond the issue text:
- the latest comments on the issue and its children;
- open and recently merged PRs, including review threads still unresolved;
- the decision cards and docs the issues link;
- design artifacts the issues link, comparing their current version with the one an issue
  says it reviewed (read the boards' text and data, not the page chrome);
- recent Slack mentions of the topic.

Then state:
- where it stands;
- what changed since the issues were written;
- whether progress is blocked on a **decision** or on **code**;
- the next concrete step.

When a newer design or decision changes the domain, list the specific deltas. Each delta is a
question for its owner, or input to a card amendment.

## 6. Focus

Recommend at most three things, then one line on what to park or delegate. In priority order:
1. Named priorities, and the specific blocker on each.
2. Decisions that unblock several streams at once, and unowned items that both priorities
   need.
3. Real deadlines found in the work (a key-rotation date, a vendor cut-off), with the date.
4. **Too much in flight:** count `In Progress` issues and open PRs. Suggest parking or handing
   to agents any stream that is mechanical and already broken down (a provider rollout
   checklist), or waiting on an outside party.

Base every point on what the data shows; never invent urgency. Say plainly when the person's
premise doesn't match the data, for example when "nearly done" has ten open children.

## 7. Clean up (interactive only, with approval)

Present the verified close candidates and ask once. Approval covers the listed items, not ones
found later. For each approved item:
- Post a comment with the evidence first. Examples:
  - "Closing: delivered by <PR URL> (merged <date>)."
  - "Closing: all child issues are done (<IDs>)."
  - "Canceling as superseded: …".
- Then set `Done`, or for a duplicate the `--duplicate-of` relation plus `Canceled`. Read each
  issue back.
- Re-check parents for the cascade (step 3) and propose any newly closable parent.

Never close on a weak link, on canceled children, or against the issue's own "postponed" note.

## 8. Triage (interactive, `depth: triage`)

For stale issues, check whether each is still relevant.
- **Batches:** split the stale issues into themed batches of about eight. Give each batch to a
  read-only subagent, and run the batches in parallel.
- **Each subagent:**
  - Does not edit files or Linear, and keeps every command short.
  - Reads the issue and its comments.
  - Checks the code and cards on the default branch (`git grep` / `git show
    origin/<branch>:…`), merged PRs, and newer issues that may supersede it.
  - Returns one block per issue: a verdict, a confidence, one to three concrete evidence
    pointers (never invented), and a one-sentence action.
- **Verdicts:**
  - `IMPLEMENTED`
  - `PARTLY-DONE` (re-scope to the remainder)
  - `STILL-RELEVANT`
  - `RE-SCOPE` (premise changed)
  - `OBSOLETE`
  - `DUPLICATE` (of which)
  - `PARKED` (waiting on what)

Give each batch the context you already hold: the parent epic, related merged PRs, and known
decisions.

Spot-check every `IMPLEMENTED` and `OBSOLETE` verdict yourself before acting. Expect most stale
issues to have drifted rather than been finished. Their pointers go stale after refactors and
newer decisions. The typical outcome is a context comment or a re-scope, not a close.
- Propose re-scopes as **comments** with the new scope, leaving the description intact.
- Apply them only on approval, as in step 7.

## Output

```markdown
🧭 **Open work — <Weekday> <d Month>**
<two sentences: N open issues (A assigned, U created and unassigned), how much is in flight
(In Progress + open PRs), and the single biggest finding>

**Focus**
1. <priority or decision> — <the blocker and the next step>
2. …
Park or delegate: <streams>

**Close candidates** (verified)
- [REP-2154](url) delivered by [#3383](url), merged 9 Oct; the cursor/ branch never linked it
- [REP-1466](url) all 5 children done
- [REP-2177](url) duplicate of [REP-2180](url)

**Priorities**
**<priority>** — <where it stands; what changed; decision or code; next step>

**Streams**
| Stream | State | Missing to close |
|---|---|---|
| [REP-2238](url) Ledger adjustments | 4/12 open; customer panel on hold | REP-2246 panel, REP-2244 re-check, REP-2247 detection |

**Stale** — N issues untouched 14+ days, mostly in <clusters>. <Name any with a real deadline.>
```

Rules:
- Link every issue and PR. Name at most three issues per cell or bullet, and count the rest.
- Every stream with open work appears once in **Streams**, most active or most important first.
  Streams with nothing in flight and nothing closable collapse into one count line.
- In scheduled mode, write close candidates and re-scopes as suggestions ("Close?"), never as
  done.
- Leave out any empty section. Emoji only on the title.

**Weekly delta (scheduled).** Read the channel's previous post from this skill. If there is
one, add a line after the headline: issues closed, issues filed, and the change in open count
since then. Name any stream that wrapped up.

## Delivery

**In chat:** print the review as Markdown and offer the cleanup (step 7) when there are close
candidates.

**To Slack** (`slack_send_message`, standard Markdown, 5,000 characters per message):
1. The top-level message is the header, the headline, the weekly delta, and **Focus**.
2. Thread replies follow, one per section: **Close candidates**, **Priorities**, **Streams**,
   **Stale**. Split further at section boundaries if a reply would exceed 5,000 characters.
3. Interactively, also print the full review in chat with the message link. As an automation,
   print only the link.

Do not set `unfurl_app_links`.
