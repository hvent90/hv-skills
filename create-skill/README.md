# create-skill

Create Claude Code skills with proper structure and best practices.

## Installation

```bash
claude mcp add-plugin hv-skills:create-skill
```

## Usage

Invoke with `/create-skill` or ask Claude to help create a skill.

## Skill Locations

```
~/.claude/skills/name/SKILL.md     # Personal (all projects)
.claude/skills/name/SKILL.md       # Project (shared via git)
plugin/skills/name/SKILL.md        # Plugin (marketplace)
```

## SKILL.md Format

```yaml
---
name: my-skill
description: What it does. When to use it.
allowed-tools: Read, Write, Bash  # Optional
---

# Instructions here
```

## Key Points

- **name**: lowercase, hyphens, max 64 chars
- **description**: include trigger phrases for discoverability
- **allowed-tools**: restrict tools when needed (omit for full access)

## Plugin Structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── skill-name/
        └── SKILL.md
```
