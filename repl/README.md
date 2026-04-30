# repl

A persistent, language-agnostic REPL skill backed by tmux. For working with data too large to fit in the agent's context — needle-in-haystack search, recursive summarization (RLM-style), or any iterative exploration where state must persist across multiple tool calls.

The skill is **guidance**, not a wrapper CLI. It teaches the agent the tmux patterns (start session, send code, sentinel-poll for completion, capture output, clean up) and the discipline of keeping data in the REPL — only metadata and reduced results cross back into agent context.

## Installation

```bash
claude mcp add-plugin hv-skills:repl
```

## Requirements

- `tmux` on PATH (`brew install tmux` on macOS)
- Whatever REPL the agent wants to drive (`python3`, `node`, `bun`, `ipython`, `ghci`, `irb`, etc.)
- For the recursive-summarization pattern: any LLM CLI the caller has on hand (`claude`, `zen`, etc.) — the skill stays neutral

## What the skill teaches

- `tmux new-session -d -s <name> -x 200 -y 50 '<repl>'` — start a detached REPL
- `tmux send-keys -t <name> -l '<code>'` then `send-keys Enter` — submit code
- Sentinel pattern (`print('__DONE_xxx__')` + poll `capture-pane`) for synchronization
- Temp-file `exec()` pattern for multi-line code without fighting Python's indent prompt
- Worked examples for needle-in-haystack and recursive summarization
- Cleanup hygiene (`tmux ls`, `tmux kill-session`)

## When the agent should use it

- A file/log/dataset is too big to read normally
- Iterative exploration where re-loading is wasteful
- Map-reduce summarization across an oversized input

## When NOT to use it

- One-shot shell commands (use Bash directly)
- Small data that fits in context
- Anything where state doesn't need to persist between calls
