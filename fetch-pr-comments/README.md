# fetch-pr-comments

Fetch unresolved PR review comments for the current branch.

## Installation

```bash
claude mcp add-plugin hv-skills:fetch-pr-comments
```

## Usage

Invoke with `/fetch-pr-comments` or ask Claude to fetch PR comments.

```bash
# All unresolved comments
/fetch-pr-comments

# Filter by reviewer
/fetch-pr-comments username
```

## Output

JSON saved to `/tmp/delete-me/{timestamp}-{repo}-{branch}.json` containing:
- Unresolved review threads with file paths and line numbers
- Pending reviews (APPROVED, CHANGES_REQUESTED, COMMENTED)

## Requirements

- GitHub CLI (`gh`) installed and authenticated
- Must be in a git repo with an open PR on the current branch
