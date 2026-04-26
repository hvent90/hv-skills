#!/usr/bin/env bun
import { readFileSync, existsSync } from "node:fs"
import { basename, resolve } from "node:path"

const SKILL_DIR = new URL(".", import.meta.url).pathname
const ENV_PATH = resolve(SKILL_DIR, ".env")

function loadEnv(): Record<string, string> {
  const out: Record<string, string> = {}
  if (!existsSync(ENV_PATH)) return out
  const raw = readFileSync(ENV_PATH, "utf8")
  for (const line of raw.split("\n")) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/i)
    if (!m) continue
    out[m[1]] = m[2].replace(/^["']|["']$/g, "")
  }
  return out
}

const env = { ...loadEnv(), ...process.env }
const TOKEN = env.DISCORD_BOT_TOKEN
const CHANNEL_ID = env.DISCORD_DM_CHANNEL_ID

if (!TOKEN || !CHANNEL_ID) {
  console.error("Missing DISCORD_BOT_TOKEN or DISCORD_DM_CHANNEL_ID")
  console.error(`Configure ${ENV_PATH}`)
  process.exit(2)
}

const args = process.argv.slice(2)
if (args.length === 0 || args.includes("-h") || args.includes("--help")) {
  console.log(`Usage: send.ts <message> [file1 file2 ...]

Sends a Discord DM to the configured user.
Files are attached (any type — images render inline, others as downloads).
Message may be empty string "" if only attaching files.`)
  process.exit(args.length === 0 ? 2 : 0)
}

const [message, ...files] = args

for (const f of files) {
  if (!existsSync(f)) {
    console.error(`File not found: ${f}`)
    process.exit(2)
  }
}

const form = new FormData()
const attachments = files.map((f, i) => ({ id: i, filename: basename(f) }))
form.append("payload_json", JSON.stringify({
  content: message || undefined,
  attachments: attachments.length ? attachments : undefined,
}))

for (let i = 0; i < files.length; i++) {
  const path = files[i]
  const data = readFileSync(path)
  form.append(`files[${i}]`, new Blob([data]), basename(path))
}

const res = await fetch(`https://discord.com/api/v10/channels/${CHANNEL_ID}/messages`, {
  method: "POST",
  headers: { Authorization: `Bot ${TOKEN}` },
  body: form,
})

if (!res.ok) {
  console.error(`Discord API error ${res.status}: ${await res.text()}`)
  process.exit(1)
}

const body = await res.json() as { id: string }
console.log(`sent ${body.id}`)
