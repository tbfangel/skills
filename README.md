# tbfangel/skills

A personal [Claude Code](https://claude.com/claude-code) plugin marketplace of skills,
organised into plugins by activity.

## Plugins

| Plugin        | Scope                                                          |
| ------------- | ------------------------------------------------------------- |
| `engineering` | Writing, reviewing, testing, and shipping code.                |
| `knowledge`   | Research, writing, documentation, and synthesising information. |

## Layout

```
.claude-plugin/
  marketplace.json          # marketplace manifest, lists the plugins below
plugins/
  engineering/
    .claude-plugin/
      plugin.json           # plugin manifest
    skills/                 # one directory per skill, each with a SKILL.md
  knowledge/
    .claude-plugin/
      plugin.json
    skills/
```

## Adding a skill

Create a directory under the relevant plugin's `skills/` folder containing a
`SKILL.md` with YAML frontmatter:

```
plugins/<plugin>/skills/<skill-name>/SKILL.md
```

```markdown
---
name: my-skill
description: One line describing when Claude should use this skill.
---

Instructions for the skill go here.
```

## Using this marketplace

```
/plugin marketplace add tbfangel/skills
/plugin install engineering@tbfangel
/plugin install knowledge@tbfangel
```
