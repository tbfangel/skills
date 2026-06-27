---
name: team-briefing
description: >
  Generate a daily team briefing that combines Slack channel activity with Linear issue updates,
  grouped by team member. Use this skill whenever someone asks for a team briefing, team update,
  daily standup summary, "what happened in [team]", or wants to know what the team has been up to
  since the last briefing. Trigger even if the user says things like "run the briefing for team X",
  "summarize team atlas today", or "what's the team been working on?" — especially when a Slack
  channel and/or Linear team are mentioned. The skill is parameterized: it accepts a source Slack
  channel to read from, a Linear team name, and an optional post channel to deliver the briefing to.
schedule: "This skill can be run as a scheduled task each weekday (Monday–Friday) to automatically
  generate and post the team briefing. When scheduling, ask the user for the preferred delivery
  time and use the /schedule skill to set up a recurring weekday run with the configured
  parameters."
---

# Team Briefing

This skill generates a combined daily briefing for a team by pulling activity from both their
Slack channel and their Linear board, then organizing everything by assignee and delivering the
summary.

## Parameters

When the user invokes this skill, identify these inputs (ask if not provided):

- **Source channel** (`source_channel`): The team's primary Slack channel to read activity from
  (e.g. `#team-atlas`). You may also look for a related sibling channel (e.g.
  `#team-atlas-devops`) — check if it exists and has activity.
- **Linear team** (`linear_team`): The Linear team name for this team (e.g. `Atlas`).
- **Post channel** (`post_channel`): Where to deliver the briefing. This defaults to the same as
  `source_channel`, but can be set to any other channel — useful for sending to a private channel
  during testing. If not specified, ask the user or fall back to `source_channel`.
- **Time window**: How far back to look. Default is **since yesterday** (last ~24 hours on
  weekdays; on Monday, look back to Friday). The user can override this.

---

## Step 1 — Gather Slack Activity

Use `slack_read_channel` to read the `source_channel` for the time window. If a sibling channel
exists (e.g. a `-devops` variant of the team channel), read that too.

For any messages that have threads, use `slack_read_thread` to read the thread. Focus on threads
with multiple replies or ones that touch on decisions, blockers, or key discussions.

**Huddles**: Look for huddle events in the channel (messages from Slackbot saying "A huddle
started", or AI huddle note links). If AI huddle notes are linked (Slack canvas files), use
`slack_read_canvas` to read them — they contain a compact summary of who attended, topics covered,
and any action items called out during the huddle.

Collect:
- Notable discussions and decisions
- Blockers or issues raised
- Announcements or updates
- Any work-in-progress mentioned by team members
- Huddle summaries (time, attendees, topics)

Tag each item with who was involved (person's name).

---

## Step 2 — Gather Linear Activity

Use the Linear MCP tools to pull activity for the specified team within the time window.

### Finding the team
Use `list_teams` to find the team ID matching the provided team name (fuzzy match is fine).

### What to pull
Run these in parallel:

1. **Recently updated issues** — Use `list_issues` filtered to this team, ordered by `updatedAt`
   descending, looking back over the time window. Focus on issues that changed status, were
   completed, newly created, or had significant updates.

2. **Comments** — For issues that show recent activity, use `list_comments` to fetch notable
   comments left by team members.

### What matters
Prioritize:
- Issues moved to "Done" or "In Review" (completions are worth celebrating)
- Issues that got stuck or moved to "Blocked"
- Newly created issues (new work starting)
- Issues with active comment threads (ongoing decisions or discussions)

Less interesting: trivial label changes, automated updates, issues with no human activity.

---

## Step 3 — Synthesize and Group by Assignee

Combine Slack and Linear data into a single coherent picture of what the team has been up to.

**Group by person — compact format**: Each active team member gets a single bullet line, not a
full section. Combine their Linear and Slack activity into one concise sentence or two short
clauses. Aim for one line per person.

Only include items that carry real signal — things that a team lead would want to know about.
Skip routine admin and coordination noise: scheduling a meeting, saying good morning, reacting to
a message, a minor acknowledgement, or any other action that doesn't reflect meaningful work or a
decision.

**Cross-references**: When a Slack discussion clearly relates to a Linear issue, weave them
together in the same bullet rather than listing them separately — e.g. "flagged GH Actions
bottleneck → Alex created ATLAS-223".

**Team-level highlights**: Compile the most important team-level items: key decisions made,
blockers that need attention, things shipped, open action items. This goes at the TOP of the
briefing, before the per-person section.

**Action points**: After the team section and huddles, derive a short list of concrete next
actions implied by the day's activity — things that clearly need to happen, with an owner. Pull
these from: Linear triage/todo items that were just created, unresolved blockers raised in Slack,
open questions from huddle notes, and anything with a due date approaching. Keep to the most
actionable 3–5 items; don't pad.

---

## Step 4 — Format and Deliver

### Message format

Write the briefing using this structure:

```
📋 *Team Briefing — [Day, Date]* | [time window, e.g. "Since Thursday"]

*🏁 Highlights*
• [Key decision or shipped thing]
• [Blocker needing attention]
• [Anything worth flagging for the whole team]

*👤 Team*
• *[Person 1]* — [compact summary: key Linear work + any meaningful Slack activity in one line]
• *[Person 2]* — [compact summary]
• *[Person 3]* — [compact summary]

:headphones: *Huddles*
• [Time range] — [who attended], covered: [topics]. [link to AI notes if available]

:white_check_mark: *Action points*
• @[Person] — [concrete next action]
• @[Person] — [concrete next action]
```

Highlights lead — the executive summary for a busy reader.
Team section is intentionally compact: one line per person, no sub-bullets, no section headers
per person. Think of it as a roll-call with a one-liner per teammate.
Huddles section only appears if there were huddles in the time window.
Action points are derived, not copied — they should read as clear instructions, not summaries.

Keep each bullet concise — one sentence is ideal. Link to Linear issues and Slack threads where
natural, but don't pad with links just to have them.

If the time window produced very little activity (e.g. a short window on a quiet day), note this
briefly rather than padding with low-signal items.

### Delivery

Always show the full briefing text in the conversation so the user can review it.

Then post using `slack_send_message` to the `post_channel` (which may differ from `source_channel`
if the user specified a separate destination, e.g. a private test channel). After posting, confirm
with a brief note: which channel it was posted to, the date range covered, and how many team
members were featured.

---

## Notes on judgment

The goal is to give the team lead (and the team) a quick, honest "what happened" — not a
bureaucratic log of every ticket touched. Prioritize signal over completeness. If there's a
compelling story (e.g. Alex finished a big PR and Sam raised a related concern in Slack),
weave it together rather than listing them separately.

When in doubt about whether to include something: ask yourself whether a team lead who missed
yesterday would want to know about it. If yes, include it. If it's routine noise, skip it.
