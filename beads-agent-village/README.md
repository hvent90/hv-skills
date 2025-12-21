# beads-agent-village

Multi-agent coordination using Beads (shared issue tracking) and MCP Agent Mail (agent messaging).

## Installation

```bash
claude mcp add-plugin hv-skills:beads-agent-village

# Install Beads
go install github.com/steveyegge/beads/cmd/bd@latest

# Install MCP Agent Mail (optional, for multi-agent coordination)
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/mcp_agent_mail/main/scripts/install.sh" | bash -s -- --yes
```

## Quick Start

```bash
bd init          # Initialize in project
bd doctor --fix  # Set up git hooks
```

## Core Commands

| Command | Purpose |
|---------|---------|
| `bd ready --json` | List unblocked work items |
| `bd create --title "..."` | Create new issue |
| `bd update ID --status done` | Update issue status |
| `bd cleanup --days 2` | Remove old issues |
| `bd sync` | Push to git |

## Multi-Agent Workflow

1. Create plan and file issues with `bd create`
2. Agents check `bd ready --json` for work
3. Claim with `bd update ID --status in_progress --assignee agent1`
4. Complete and sync: `bd update ID --status done && bd sync`

## Beads Viewer (bv)

Terminal UI for issue visualization:

```bash
# Install
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_viewer/main/install.sh" | bash

# For agents, use robot commands (non-interactive)
bv --robot-triage    # Full triage with recommendations
bv --robot-next      # Single top pick
bv --robot-plan      # Parallel execution tracks
```

## Resources

- [Beads](https://github.com/steveyegge/beads)
- [Beads Viewer](https://github.com/Dicklesworthstone/beads_viewer)
- [MCP Agent Mail](https://github.com/Dicklesworthstone/mcp_agent_mail)
