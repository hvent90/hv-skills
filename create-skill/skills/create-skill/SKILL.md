---
name: create-skill
description: Create Claude Code skills with proper structure, frontmatter, and best practices. Use when the user wants to create a new skill, write a SKILL.md file, or needs help structuring a Claude Code plugin.
allowed-tools: Bash, Read, Write, Glob, Grep
---

# Create Claude Code Skills

Guide for creating well-structured Claude Code skills that are discoverable and effective.

## Skill Directory Structure

Skills can be placed in three locations:

```
# Personal skills (available across all projects)
~/.claude/skills/skill-name/SKILL.md

# Project skills (shared via git with team)
.claude/skills/skill-name/SKILL.md

# Plugin skills (distributed via marketplace)
plugin-name/skills/skill-name/SKILL.md
```

## SKILL.md Format

Every skill requires a `SKILL.md` file with YAML frontmatter:

```yaml
---
name: your-skill-name
description: Brief description of what this Skill does and when to use it
allowed-tools: Tool1, Tool2, Tool3  # Optional: restricts available tools
---

# Skill Title

## Instructions
Clear, step-by-step guidance for Claude.

## Examples
Concrete examples of using this skill.
```

## Frontmatter Fields

### Required Fields

| Field | Rules | Example |
|-------|-------|---------|
| `name` | Lowercase, numbers, hyphens only. Max 64 chars. | `pdf-processor` |
| `description` | What it does AND when to use it. Max 1024 chars. | `Extract text from PDFs. Use when working with PDF files or document extraction.` |

### Optional Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `allowed-tools` | Restrict which tools Claude can use | `Read, Grep, Glob` |

## Writing Effective Descriptions

The description is critical for discoverability. Include:

1. **What the skill does** - the capability
2. **When to use it** - trigger phrases and contexts

### Good Examples

```yaml
description: Generate clear git commit messages from staged changes. Use when writing commits, reviewing diffs, or preparing code for push.
```

```yaml
description: Analyze Excel spreadsheets, create pivot tables, and generate charts. Use when working with Excel files, .xlsx format, or tabular data analysis.
```

### Bad Examples

```yaml
# Too vague - Claude won't know when to use it
description: Helps with documents

# Missing trigger context
description: Processes PDF files
```

## Tool Restrictions with allowed-tools

Use `allowed-tools` to limit Claude's capabilities when the skill is active:

```yaml
---
name: code-reviewer
description: Review code for best practices. Use when reviewing PRs or analyzing code quality.
allowed-tools: Read, Grep, Glob
---
```

Common tool combinations:

| Use Case | Recommended Tools |
|----------|-------------------|
| Read-only analysis | `Read, Grep, Glob` |
| File operations | `Read, Write, Edit, Glob` |
| Shell scripts | `Bash, Read, Write` |
| Web research | `WebFetch, WebSearch, Read, Write` |
| Full access | Omit `allowed-tools` entirely |

## Multi-File Skills

For complex skills, add supporting files:

```
my-skill/
├── SKILL.md           # Required: main instructions
├── reference.md       # Optional: detailed documentation
├── examples.md        # Optional: usage examples
├── scripts/
│   └── helper.py      # Optional: utility scripts
└── templates/
    └── template.txt   # Optional: templates
```

Reference files from SKILL.md:

```markdown
For advanced usage, see [reference.md](reference.md).
```

Claude loads additional files only when needed (progressive disclosure).

## Creating a Plugin Skill

For marketplace distribution, create this structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── skill-name/
        └── SKILL.md
```

### plugin.json Format

```json
{
  "name": "plugin-name",
  "description": "Brief plugin description",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
```

## Skill Creation Checklist

When creating a skill:

1. [ ] Choose a descriptive, hyphenated name
2. [ ] Write a specific description with trigger phrases
3. [ ] Decide on tool restrictions (if any)
4. [ ] Create clear, actionable instructions
5. [ ] Add examples for common use cases
6. [ ] List any requirements (CLI tools, packages)
7. [ ] Test by asking questions that match the description

## Common Patterns

### Simple Skill (Single File)

```yaml
---
name: commit-message-generator
description: Generate clear commit messages from git diffs. Use when writing commits or reviewing staged changes.
---

# Commit Message Generator

## Instructions

1. Run `git diff --staged` to see changes
2. Generate a commit message with:
   - Summary under 50 characters
   - Detailed description of what and why
   - List affected components

## Format

- Use present tense ("Add feature" not "Added feature")
- First line is the subject, then blank line, then body
```

### Script-Based Skill

```yaml
---
name: api-tester
description: Test REST API endpoints with curl. Use when testing APIs or debugging HTTP requests.
allowed-tools: Bash, Read, Write
---

# API Tester

## Usage

Test an endpoint:

```bash
./scripts/test-api.sh GET https://api.example.com/users
```

## Scripts

- `scripts/test-api.sh` - Main testing script
- `scripts/format-json.sh` - Pretty print JSON responses
```

### Read-Only Analysis Skill

```yaml
---
name: security-scanner
description: Scan code for security vulnerabilities. Use when reviewing code security or checking for OWASP issues.
allowed-tools: Read, Grep, Glob
---

# Security Scanner

This skill provides read-only security analysis.

## Checks

1. Hardcoded credentials
2. SQL injection vulnerabilities
3. XSS attack vectors
4. Insecure dependencies
```

## Debugging Skills

If Claude doesn't use your skill:

1. **Check description specificity** - Add trigger phrases
2. **Verify file path** - Must be in correct location
3. **Validate YAML** - Check for syntax errors
4. **Run with debug** - `claude --debug` shows loading errors

## Requirements

When creating skills for this marketplace:
- Follow the plugin structure with `.claude-plugin/plugin.json`
- Place skills in `skills/skill-name/SKILL.md`
- Update the root `marketplace.json` to register the plugin
