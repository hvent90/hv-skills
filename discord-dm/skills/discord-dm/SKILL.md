---
name: discord-dm
description: Use when you need to send the user a Discord DM — proactive notifications, finished long-running task pings, sharing a generated image or screenshot, asking a question when the user is away from terminal. One CLI call sends text and/or file attachments.
---

# Discord DM

Sends a DM to the user via the configured Discord bot. Text + arbitrary file attachments (images render inline).

## Usage

```bash
bun ${CLAUDE_PLUGIN_ROOT}/skills/discord-dm/send.ts "<message>" [file1 file2 ...]
```

- `<message>` — required positional. Pass `""` to send only attachments.
- Files — optional. Any type. Images preview inline in Discord; other files appear as downloads.
- On success prints `sent <message_id>` and exits 0. On failure prints the Discord error and exits non-zero.

## Examples

```bash
# Plain text
bun ${CLAUDE_PLUGIN_ROOT}/skills/discord-dm/send.ts "Build finished — all green."

# Text + image
bun ${CLAUDE_PLUGIN_ROOT}/skills/discord-dm/send.ts "Here's the chart" /tmp/chart.png

# Multiple attachments, no text
bun ${CLAUDE_PLUGIN_ROOT}/skills/discord-dm/send.ts "" /tmp/before.png /tmp/after.png
```

## Configuration

Create a `.env` next to `send.ts` with `DISCORD_BOT_TOKEN` and `DISCORD_DM_CHANNEL_ID`. Both must be set; the script exits with code 2 if missing. Env vars in the calling shell override the file.

```
DISCORD_BOT_TOKEN=your-bot-token
DISCORD_DM_CHANNEL_ID=your-dm-channel-id
```

To get the DM channel ID, have your bot open a DM channel with your user ID via the Discord API (`POST /users/@me/channels` with `recipient_id`) — the returned channel ID goes here.

## Notes

- Discord caps a single message at 2000 chars of content. The script does not split — keep messages short or send multiple calls.
- Total attachment payload limit is ~25MB without Nitro.
- Don't use this for routine status chatter mid-conversation — the user can already see your output. Reserve it for pings the user wouldn't otherwise see.
