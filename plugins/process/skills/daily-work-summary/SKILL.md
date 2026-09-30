---
name: daily-work-summary
description: >
  Summarize one person's own work from GitHub and Linear. Morning mode gives an overview before
  starting work: what carried over from the previous working day and where each stream of work
  was left, with open pull requests and in-progress Linear issues grouped by their top-level
  issue. Evening mode gives an appreciative rundown of what they shipped, closed, reviewed, and
  filed today. Prints to the chat, or posts to a Slack channel when one is given (always when run
  as an automation). Use when the user asks for their "morning summary", "evening summary",
  "what am I working on", "what was I doing yesterday", "what did I do today", "daily recap",
  "end-of-day rundown", or "my daily summary".
---

# Daily Work Summary

Two modes over the same sources: **morning** (what carried over and where each thread was left)
and **evening** (what got done today). Both cover only the invoking person's own work.

## Parameters

- **Mode** (`mode`): `morning` or `evening`. If not given, infer from the local time: before
  12:00 is morning, otherwise evening. Say which mode was inferred in one line.
- **Slack channel** (`slack_channel`): optional channel ID or URL
  (`https://<workspace>.slack.com/archives/<ID>` → `<ID>`). When given, post the summary there.
  When run as an automation, this is required; if it is missing, stop and say so rather than
  printing into a log nobody reads.
- **Linear team** (`linear_team`): optional. If not given, use every team the person belongs to.

The person is whoever is authenticated: `gh api user -q .login` for GitHub, `linear auth status`
(`.user.id`) or the Linear MCP `get_user` with `me` for Linear. Do not ask for these.

"Today" is the local calendar day. Take the date and UTC offset from `date +%F` and `date +%z`, and
pass full timestamps (`2026-09-30T00:00:00+02:00`) to GitHub search so a merge at 01:00 local time
is not lost to UTC.

**The activity window** is today in evening mode. In morning mode it is the previous working
day, from its local midnight until now, so that anything done late last night or over the weekend
is included. On Monday the previous working day is Friday.

## Tools

Prefer the `gh` and `linear` (linearis) CLIs; they return compact JSON. If a CLI is missing or
unauthenticated (common in cloud automations), use the GitHub and Linear MCP tools for the same
queries. If a source is unreachable by either route, say which one in the output instead of
silently leaving its section out.

Known linearis quirks:
- `--completed-after` returns nothing. For completions, use `--status Done --team <team>
  --updated-after <window start>` instead. This also matches an issue completed earlier and
  edited in the window, so cross-check against the window's merged PRs (branch names carry the
  issue ID) and drop Done issues with no other sign of being finished in the window.
- `--status` requires `--team`.
- There is no `completedAt` field in the list output.
- `--parent <id>` lists only the **open** children. `issues read <id>` lists every child ID, but
  not their states. A parent with children in `read` and none from `--parent` has all of its
  children finished.

## Gather — GitHub

Open PRs authored by the person, with their state and where they were left (one call):

```bash
gh api graphql -f query='query{search(query:"author:@me is:pr is:open archived:false",type:ISSUE,first:50){nodes{... on PullRequest{number title url isDraft createdAt reviewDecision mergeable headRefName updatedAt repository{nameWithOwner} commits(last:5){nodes{commit{messageHeadline committedDate statusCheckRollup{state}}}} reviewThreads(first:50){nodes{isResolved path comments(last:1){nodes{author{login} body}}}}}}}}'
```

- The CI state is the rollup on the **last** commit. When it is failing, name the failing checks
  with `gh pr checks <n> --repo <owner/repo>`.
- For each unresolved thread, summarize what the last comment asks for in a few words. Bot
  bodies start with HTML comments and metadata; skip past them to the actual request.
- Skip merge commits when reporting the last commit. The last non-merge headline says what was
  being worked on.

Both modes also need activity in the window. Replace `<since>` with the window's start
timestamp:

- Merged: `search(query:"author:@me is:pr merged:>=<since>")`, also selecting `additions
  deletions changedFiles mergedAt`.
- Opened and still open: `author:@me is:pr is:open created:>=<since>`.
- Pushed to: an open PR with a commit whose `committedDate` falls in the window (from the open-PR
  query above).
- Reviewed: `reviewed-by:@me is:pr updated:>=<since> -author:@me`. `updated` is only a proxy for
  the review date, so describe these as "reviews on", not "reviews submitted today".

Linked Linear issue: branch names carry the issue ID (`feat/rep-1740-…` → `REP-1740`). Use it to
attach each PR to its issue, and to its top-level issue for grouping.

## Gather — Linear

- **In flight**: issues assigned to the person in a started state (`In Progress`, `In Review`,
  or the team's equivalent).
- **Done in the window**: assigned, `Done`, updated in the window — see the quirk above.
- **Filed in the window**: created by the person in the window, any assignee.
- **Touched in the window** (morning): assigned, not Done, updated in the window.
- **What is left in each stream** (morning): for each top-level issue that has activity in the
  window or holds in-flight work, list its open descendants with `--parent`, recursing into any
  open child that has children of its own. Record each one's state and assignee. Note the `Todo`
  items assigned to the person or unassigned; they are the candidates for what comes next.

**Top-level issue.** For each issue, follow `parent` until an issue has none; that root is the
group heading. Resolve each distinct parent once with `linear issues read <id>` and cache it,
since many issues share roots. An issue with no parent is its own group only if it has children;
otherwise it goes under **Standalone**.

## Emoji use

Go easy on emojis. Use one on the title (☀️ or 🌇), ⚠️ on **Needs attention**, and 🎉 on the
contribution heading. CI status may use ✅ and ❌ as markers. Nothing else gets one: no emoji
on other section headings, bullets, stats, or the closing line.

## Morning output

Answer "where did I leave things, and what am I carrying into today?". The reader has many
things going at once and has forgotten the details overnight. Organize by **stream**, meaning a
top-level issue, so each thread of work reads as a single story: what moved yesterday, what is
still open, and where it was left. Keep it scannable in under two minutes.

```markdown
☀️ **Good morning — <Weekday> <d Month>**
<one or two sentences: yesterday in a nutshell (N PRs merged across which streams), how many PRs
and issues carry over, and the one thing that most needs attention>

**⚠️ Needs attention**
- [#2725](url) Remove each dbtest container… — merge conflict; 2 unresolved threads (cubic: the
  teardown can race abandoned creates; ADR card ID doesn't match its commit time)
- [#2743](url) Connect Uniconta… — `Test and build` failing (draft)

**Picking up where you left off** (streams with activity yesterday, most active first)

**[REP-1732](url) Add Uniconta accounting integration**
- *Yesterday:* opened draft [#2743](url) for [REP-1740](url); last commit 16:53 "Describe the
  Uniconta connection ACL on its cards"
- *Still open:* #2743 (draft · CI ❌) · REP-1740 In Progress · [REP-1733](url) Todo — developer
  access, which gates qualification
- *Next:* get `Test and build` green on #2743

**[REP-1345](url) Map synchronized accounts onto statutory statement lines**
- *Yesterday:* merged 4 PRs — the ÅRL statement is calculated and chart mapping is in production
- *Still open:* 10 issues, none in progress · Todo: [REP-1744](url) closing postings,
  [REP-1501](url) mapper proposals

**Wrapped up** — streams whose children are all done but whose top-level issue is still open.
- [REP-1671](url) Support view — all 6 children done; the parent is still Backlog. Close it?

**Also in flight** (no activity yesterday)
**[REP-9](url) Convert existing integrations to Go**
- [REP-36](url) Port Billy · In Progress · 1 open child ([REP-865](url))
- [REP-37](url) Port Business Central · In Progress · 2 open children, 1 yours ([REP-804](url))
```

Rules:
- **Every open PR and every in-flight issue appears exactly once**: in the stream that owns it,
  under *Picking up* if the stream had activity in the window, otherwise under *Also in flight*.
  Standalone items (no top-level issue) form a **Standalone** stream in the same way.
- *Yesterday* says what moved, in product terms, with the last non-merge commit headline and time
  for PRs that were pushed to. Collapse merged PRs to a count plus the outcome; the evening
  rundown already listed them.
- *Still open* gives each open PR's state (draft/ready · CI · conflicts · N unresolved) with its
  issue ID, and the stream's remaining issues. Name at most three; summarize the rest as a count.
- *Next* is optional and only states the obvious next action that follows from the state: fix
  the failing check, resolve the threads, rebase, or pick up the one Todo that is assigned to the
  person. Omit it rather than guess.
- **Needs attention** lists only actionable blockers on the person's own work: failing CI,
  merge conflicts, unresolved review threads (with the gist of each), changes requested, a ready
  PR with no review decision for over a day, or an in-progress issue with no open PR and no
  update for 3+ days. Omit the section when nothing qualifies.
- **Wrapped up** is where a stream finished in the window lands, not in *Picking up*. It is a
  prompt to close the parent, and worth acknowledging in one clause.
- A stream whose in-progress issue has had no activity in a week gets flagged as possibly stale,
  not hidden.

## Evening output

Answer "what did I get done today?", then acknowledge it. Lead with outcomes, not a log, and keep
it easy on the eye: short sections with blank lines between them, one short line per bullet, and
no paragraph longer than two sentences. A long day gets more sections, not longer ones.

```markdown
🌇 **Today's rundown — <Weekday> <d Month>**

**Shipped**

**REP-1466 Per-fiscal-year accounting facts**
- [#2345](url) Capture unbooked entries for Billy, BC, and Fake ERP · +4.4k −357
- [#2722](url) Issue the unbooked-entries Task in production · +262 −694

**REP-1671 Support view**
- [#2681](url) Admit Employee-matched Actors through a support-access grant · +1.7k −43

**Closed in Linear**
- [REP-1519](url) Country-scope the Danish statutory line vocabulary

**Reviewed**
- [#2451](url) LedgerBee accounting gateway (Kledal)

**Started**
- [#2743](url) Connect Uniconta through a sealed server-user login (draft)

**Planned** — 10 issues filed
- [REP-1737](url) Approve, lock, and store a financial statement
- [REP-1744](url) Keep year-end closing postings out of income
- …and 8 more

---

**🎉 Your contribution today**

**20** PRs merged · **22** issues closed · **+30.2k / −2.4k** lines · **1** review · **10** filed

- **Unbooked entries are live in production**: capture → customer panel → back office
- **Chart mapping shipped**, and it feeds the first calculated ÅRL statement
- **Support view, end to end**: from access grant to banner in one day

**The standout:** the ÅRL statement, the first annual-report figure computed from synced ledgers.

<one short, plain closing line, e.g. "Tomorrow's work is already filed. A solid day.">
```

Layout rules:
- **Shipped** is grouped by top-level issue, with a blank line between groups. Shorten each PR
  title to its gist: drop the `[project]` prefix and trailing qualifiers. Give line counts in
  compact form (`+4.4k −357`). The Linear ID is dropped from the line, since the group heading
  and the PR link carry it.
- Each of the other sections is its own heading with bullets under it, never a run-on line.
  Omit any section that is empty. **Planned** names at most three issues, the most
  consequential first, and counts the rest.
- A horizontal rule separates the log above from the contribution summary below.

The contribution summary:
- Opens with the stats line: PRs merged, issues closed, lines added and removed, reviews, and
  issues filed. Leave out any stat that is zero.
- Follows with two or three theme bullets, each a bold outcome in product terms plus a short
  clause of how ("the unbooked-entries Task is live in production"), not a restatement of PR
  titles.
- Then one **standout** line: the hardest or most consequential piece, and why it matters.
- Ends with one short closing line.
- **Tone:** appreciative and understated, like a colleague who noticed the work, not a hype
  reel. Let the specifics carry the praise. Avoid superlatives, exclamation marks, and phrases
  like "victory lap", "crushed it", "what a day", or "great job". Scale the acknowledgement to
  the day: a heavy shipping day gets a plain "a solid day"; a day of reviews, research, or one
  gnarly fix is acknowledged for what it was, never apologized for.
- Never inflates. Do not claim impact the data does not show, and never invent numbers.

## Delivery

**In chat:** print the summary as Markdown. Nothing else is needed.

**To Slack** (`slack_send_message`, standard Markdown, 5,000 characters per message):
1. Post the top-level message. In morning mode: the header, the recap sentence, and **Needs
   attention**. In evening mode: the header and the whole contribution summary. This is what
   the channel sees.
2. Reply in its thread (`thread_ts` from the first post) with the detail sections. In evening
   mode, post **Shipped** as one reply and the remaining sections (Closed, Reviewed, Started,
   Planned) as a second, so no single message is a wall. Split further at section boundaries if
   a reply would exceed 5,000 characters.
3. When run interactively, also print the full summary in chat and give the message link. When
   run as an automation, print only the link.

Link every PR and Linear issue. Do not set `unfurl_app_links`; a dozen link previews bury the
summary.
