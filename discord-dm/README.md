# discord-dm

Send the user a Discord DM via a configured bot. Useful for proactive notifications, long-running task completions, sharing generated images, or pinging the user when they're away from the terminal.

## Installation

```bash
claude mcp add-plugin hv-skills:discord-dm
```

## Configuration

Create a `.env` file next to `send.ts` (in `skills/discord-dm/`) with:

```
DISCORD_BOT_TOKEN=your-bot-token
DISCORD_DM_CHANNEL_ID=your-dm-channel-id
```

Both are required. Env vars in the calling shell override the file.

To obtain the DM channel ID: have your bot call Discord's `POST /users/@me/channels` with your user ID as `recipient_id`. The returned channel ID is what you put in the env file.

## Usage

```bash
# Plain text
bun ${CLAUDE_PLUGIN_ROOT}/skills/discord-dm/send.ts "Build finished — all green."

# Text + image
bun ${CLAUDE_PLUGIN_ROOT}/skills/discord-dm/send.ts "Here's the chart" /tmp/chart.png

# Attachments only (empty message string)
bun ${CLAUDE_PLUGIN_ROOT}/skills/discord-dm/send.ts "" /tmp/before.png /tmp/after.png
```

On success prints `sent <message_id>` and exits 0.

## Requirements

- [Bun](https://bun.sh) installed
- A Discord bot with permission to DM the target user
