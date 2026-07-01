---
name: daily-slack-briefing
description: >
  Generate a personal Slack briefing for a specified user — surface direct mentions and activity
  in threads they're part of, summarized concisely with direct links, and post it to a specified
  channel. The skill is parameterized: it accepts the Slack user to generate the briefing for and
  a destination channel to post it to. Use whenever the user asks for a "Slack briefing", "what
  happened in Slack", "what do I need to catch up on in Slack", "Slack summary", or "what was I
  mentioned in".
---

# Daily Slack Briefing

Check Slack for direct mentions and updates in threads where the configured user takes part in the discussion.

The output must be a list of messages and threads where there was activity or where they were mentioned directly.

## Parameters

- **Slack user** (`slack_user`): The person to generate the briefing for (e.g. `@thomas` or their
  Slack user ID). Defaults to the person invoking the skill if not specified — ask if it can't be
  inferred.
- **Post channel** (`post_channel`): Where to deliver the briefing (e.g. `#my-slack-summary`).
  Ask the user for this if it isn't provided and hasn't been established in an earlier
  invocation.

## Time window

- On Mondays, cover the period since the previous Friday's briefing.
- On other weekdays, cover the period since the briefing the day before.

## Rules for summary entries

- Be concise in the summaries.
- Include a link directly to the message/thread.
- Highlight the summary description in **bold** so it stands out when glancing over the post.
- Use headers to divide the types of messages.
- Highlight headers in bold, or using emojis.

## Delivery

Post the summary in the configured `post_channel`.
