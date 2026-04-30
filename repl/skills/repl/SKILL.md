---
name: repl
description: Use when you need to work with data too large to fit in your context — needle-in-haystack search across huge logs/files/datasets, recursive summarization (RLM-style), or iterative exploration where state must persist across multiple tool calls. Backed by a persistent tmux session running any REPL (python, ipython, node, bun repl, ghci, irb, etc.).
---

# REPL

A persistent, language-agnostic REPL session. Use it when loading the full data into your own context would be wasteful or impossible.

## When to use

- A file/dataset/log too big to read fully (50MB JSON, hour of logs, large vector dump)
- Iterative exploration where you want state to persist across calls (build up a dataframe, accumulate summaries)
- **Recursive Language Model (RLM)** — chunk a huge input, shell out to an LLM CLI per chunk, collect summaries, optionally re-summarize the summaries

## The cardinal rule

**Data lives in the REPL. Only metadata and small results cross back into your context.**

Never `print(data)` on the full variable. Print:
- `len(data)` / `type(data)` / `data.keys()`
- `data[:500]` for orientation
- Filtered hits, counts, summaries
- Anything you've already reduced

If you accidentally print the whole thing, your context is now polluted with what you were trying to avoid loading. Be deliberate.

## Mechanics

State is held by a detached `tmux` session. Each invocation of `tmux send-keys` / `capture-pane` is one round-trip; the REPL stays alive between them.

### Start a session

```bash
tmux new-session -d -s <name> -x 200 -y 50 '<repl-command>'
```

- `-d` detached, `-s <name>` your chosen session name, `-x 200 -y 50` virtual terminal size (matters — `capture-pane` only sees what fits).
- `<repl-command>` is anything: `python3 -i`, `ipython`, `node`, `bun repl`, `ghci`, `irb`, `julia`, etc.

Examples:

```bash
tmux new-session -d -s explore -x 200 -y 50 'python3 -i'
tmux new-session -d -s js -x 200 -y 50 'node'
tmux new-session -d -s logs -x 200 -y 50 'ipython --no-banner'
```

### Send code and wait for it to finish (sentinel pattern)

The REPL is async — `send-keys` returns immediately. To know when execution is done, append a sentinel print and poll `capture-pane` until the sentinel appears at least **twice** (once as the typed echo, once as the printed output).

```bash
SENTINEL="__DONE_$(date +%s%N)__"
tmux send-keys -t explore -l "your_code_here; print('$SENTINEL')"
tmux send-keys -t explore Enter

# poll until sentinel shows up twice (echo + output)
while [ "$(tmux capture-pane -t explore -p -S -500 | grep -c "$SENTINEL")" -lt 2 ]; do
  sleep 0.2
done

tmux capture-pane -t explore -p -S -500
```

Adjust `-S -500` (lines of scrollback) if your output is bigger. Adjust `sleep 0.2` if you expect long-running code.

### Multi-line code (Python indentation, function defs, etc.)

Don't try to `send-keys` Python blocks line-by-line — the indent prompt `...` will fight you. Write to a temp file and `exec` it:

```bash
cat > /tmp/repl_block.py <<'EOF'
def find_hits(text, needle):
    return [i for i, line in enumerate(text.split("\n")) if needle in line]

hits = find_hits(data, "ERROR")
print(f"{len(hits)} hits, first 5: {hits[:5]}")
EOF

SENTINEL="__DONE_$(date +%s%N)__"
tmux send-keys -t explore -l "exec(open('/tmp/repl_block.py').read()); print('$SENTINEL')"
tmux send-keys -t explore Enter

while [ "$(tmux capture-pane -t explore -p -S -500 | grep -c "$SENTINEL")" -lt 2 ]; do
  sleep 0.2
done
tmux capture-pane -t explore -p -S -500
```

Equivalents in other REPLs:
- Node: write to `/tmp/x.js`, then `.load /tmp/x.js` in node REPL, or `eval(require('fs').readFileSync('/tmp/x.js', 'utf8'))`
- Ruby: `load '/tmp/x.rb'`
- Haskell (ghci): `:load /tmp/x.hs`

### List and clean up

```bash
tmux list-sessions                        # what's running
tmux kill-session -t <name>               # kill one
tmux kill-server                          # kill all (use sparingly — may affect other apps)
```

**Always kill sessions you started when you're done.** Long-lived sessions hold memory and live across Claude Code restarts.

### Inspect manually (the user can too)

```bash
tmux attach -t <name>     # attach interactively
# detach with: Ctrl-b d
```

## Pattern: needle in haystack

Goal: find specific things in data too big to read normally.

```bash
# Start session
tmux new-session -d -s logs -x 200 -y 50 'python3 -i'

# Load data (stays in REPL, NOT in your context)
SENTINEL="__DONE_$(date +%s%N)__"
tmux send-keys -t logs -l "data = open('/var/log/big.log').read(); print(f'len={len(data)}'); print('$SENTINEL')"
tmux send-keys -t logs Enter
while [ "$(tmux capture-pane -t logs -p -S -200 | grep -c "$SENTINEL")" -lt 2 ]; do sleep 0.2; done
tmux capture-pane -t logs -p -S -200
# -> "len=42857193"  (42MB log; you only see the length)

# Search
cat > /tmp/search.py <<'EOF'
hits = [(i, line) for i, line in enumerate(data.split("\n")) if "OOMKilled" in line]
print(f"found {len(hits)} hits")
for i, line in hits[:5]:
    print(f"line {i}: {line[:200]}")
EOF

SENTINEL="__DONE_$(date +%s%N)__"
tmux send-keys -t logs -l "exec(open('/tmp/search.py').read()); print('$SENTINEL')"
tmux send-keys -t logs Enter
while [ "$(tmux capture-pane -t logs -p -S -500 | grep -c "$SENTINEL")" -lt 2 ]; do sleep 0.2; done
tmux capture-pane -t logs -p -S -500
# -> only the matches cross back into your context
```

## Pattern: recursive summarization (RLM-style)

Goal: summarize input that's too big for any single LLM call. Chunk it in the REPL, summarize each chunk via a sub-LLM call (shell out to whatever LLM CLI you have — `claude -p`, `zen`, etc. — caller's discretion), then combine.

```bash
tmux new-session -d -s rlm -x 200 -y 50 'python3 -i'

# Load
SENTINEL="__DONE_$(date +%s%N)__"
tmux send-keys -t rlm -l "doc = open('/tmp/huge.md').read(); print(f'len={len(doc)}'); print('$SENTINEL')"
tmux send-keys -t rlm Enter
while [ "$(tmux capture-pane -t rlm -p -S -200 | grep -c "$SENTINEL")" -lt 2 ]; do sleep 0.2; done

# Map: summarize chunks. The sub-LLM CLI is up to you — claude -p, zen, etc.
cat > /tmp/rlm_map.py <<'EOF'
import subprocess, textwrap

CHUNK = 8000
chunks = [doc[i:i+CHUNK] for i in range(0, len(doc), CHUNK)]
print(f"{len(chunks)} chunks")

summaries = []
for i, chunk in enumerate(chunks):
    prompt = f"Summarize this section in 3 bullets:\n\n{chunk}"
    # Substitute whatever LLM CLI you have available:
    out = subprocess.run(
        ["claude", "-p", prompt],
        capture_output=True, text=True, timeout=120,
    )
    summaries.append(out.stdout.strip())
    print(f"  chunk {i+1}/{len(chunks)} done ({len(out.stdout)} chars)")
EOF

SENTINEL="__DONE_$(date +%s%N)__"
tmux send-keys -t rlm -l "exec(open('/tmp/rlm_map.py').read()); print('$SENTINEL')"
tmux send-keys -t rlm Enter
while [ "$(tmux capture-pane -t rlm -p -S -500 | grep -c "$SENTINEL")" -lt 2 ]; do sleep 0.2; done

# Reduce: combine the summaries (they may now fit in one call; if not, recurse)
cat > /tmp/rlm_reduce.py <<'EOF'
import subprocess
joined = "\n\n---\n\n".join(summaries)
print(f"combined len={len(joined)}")
out = subprocess.run(
    ["claude", "-p", f"Combine these section summaries into one coherent summary:\n\n{joined}"],
    capture_output=True, text=True, timeout=180,
)
final = out.stdout.strip()
print("=== FINAL ===")
print(final)
EOF

SENTINEL="__DONE_$(date +%s%N)__"
tmux send-keys -t rlm -l "exec(open('/tmp/rlm_reduce.py').read()); print('$SENTINEL')"
tmux send-keys -t rlm Enter
while [ "$(tmux capture-pane -t rlm -p -S -1000 | grep -c "$SENTINEL")" -lt 2 ]; do sleep 0.2; done
tmux capture-pane -t rlm -p -S -1000
```

If the joined summaries are still too big, run another map/reduce pass over `summaries` — that's the recursion. The REPL holds all intermediate state; only the final answer needs to come back to you.

## Output hygiene

`capture-pane` returns the pane buffer including prompts, the typed line, and the sentinel. After capturing, the useful output is between the typed line and the sentinel echo. Trim accordingly when reasoning about results — or just instruct yourself to ignore the noise.

If output is genuinely large and you only want the tail, `capture-pane -S -100` keeps the last ~100 lines of scrollback.

## Common pitfalls

- **Forgetting `Enter`**: `send-keys -l "code"` types the code but doesn't submit. Always follow with `send-keys Enter`.
- **Forgetting `-l`**: without `-l`, `send-keys` interprets words like `Space`, `Tab`, `Enter` as keynames. Always use `-l` for code.
- **Tiny pane**: default tmux pane (80x24) truncates output. Use `-x 200 -y 50` (or larger) when creating the session.
- **No sentinel**: if you don't sentinel, you race the REPL — capture too soon and miss output, capture too late and waste time. Always sentinel.
- **Single-quote collisions**: if your code contains `'`, switch the outer `send-keys` quoting to single-with-escapes, or use the temp-file pattern.
- **Leftover sessions**: `tmux ls` periodically. Sessions survive Claude Code restarts.
- **Printing the whole variable**: re-read the cardinal rule. Print metadata, not data.
