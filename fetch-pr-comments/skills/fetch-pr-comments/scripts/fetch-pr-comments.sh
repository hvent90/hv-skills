#!/usr/bin/env bash
#
# Fetches unresolved PR review comments and feedback from the current branch.
# Optionally filters by a specific reviewer.
#
# Usage:
#   ./fetch-pr-comments.sh              # All unresolved comments
#   ./fetch-pr-comments.sh username     # Filter by specific user

set -euo pipefail

FILTER_USER="${1:-}"

# Get PR metadata for current branch
PR_INFO=$(gh pr view --json number,headRefName 2>/dev/null) || {
  echo "Error: No pull request found for current branch." >&2
  echo "Make sure you're on a branch with an open PR." >&2
  exit 1
}

PR_NUMBER=$(echo "$PR_INFO" | jq -r '.number')
BRANCH=$(echo "$PR_INFO" | jq -r '.headRefName')

# Get repo info
REPO_INFO=$(gh repo view --json owner,name)
OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
REPO=$(echo "$REPO_INFO" | jq -r '.name')

# Create output directory
OUTPUT_DIR="/tmp/delete-me"
mkdir -p "$OUTPUT_DIR"

# Generate timestamp and filename
TIMESTAMP=$(date -u +"%Y-%m-%dT%H%M%S")
SAFE_BRANCH=$(echo "$BRANCH" | tr '/' '-')
OUTPUT_FILE="${OUTPUT_DIR}/${TIMESTAMP}-${REPO}-${SAFE_BRANCH}.json"

# Fetch review threads using GraphQL
GRAPHQL_QUERY='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          comments(first: 100) {
            nodes {
              author { login }
              body
              path
              line
              createdAt
            }
          }
        }
      }
    }
  }
}
'

THREADS_RESPONSE=$(gh api graphql \
  -f query="$GRAPHQL_QUERY" \
  -f owner="$OWNER" \
  -f repo="$REPO" \
  -F pr="$PR_NUMBER")

# Extract unresolved threads, optionally filter by user
if [ -n "$FILTER_USER" ]; then
  UNRESOLVED_THREADS=$(echo "$THREADS_RESPONSE" | jq --arg user "$FILTER_USER" '
    .data.repository.pullRequest.reviewThreads.nodes
    | map(select(.isResolved == false))
    | map({
        path: .comments.nodes[0].path,
        line: .comments.nodes[0].line,
        comments: [.comments.nodes[] | select(.author.login == $user) | {
          author: .author.login,
          body: .body,
          created_at: .createdAt
        }]
      })
    | map(select(.comments | length > 0))
  ')
else
  UNRESOLVED_THREADS=$(echo "$THREADS_RESPONSE" | jq '
    .data.repository.pullRequest.reviewThreads.nodes
    | map(select(.isResolved == false))
    | map({
        path: .comments.nodes[0].path,
        line: .comments.nodes[0].line,
        comments: [.comments.nodes[] | {
          author: .author.login,
          body: .body,
          created_at: .createdAt
        }]
      })
  ')
fi

# Fetch overall reviews
REVIEWS_RESPONSE=$(gh api "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/reviews")

# Filter reviews by user if specified
# Exclude DISMISSED reviews and empty COMMENTED reviews (which are just containers for inline comments)
if [ -n "$FILTER_USER" ]; then
  PENDING_REVIEWS=$(echo "$REVIEWS_RESPONSE" | jq --arg user "$FILTER_USER" '
    [.[] | select(
      .user.login == $user and
      .state != "DISMISSED" and
      (.state != "COMMENTED" or (.body != "" and .body != null))
    ) | {
      user: .user.login,
      state: .state,
      body: .body,
      submitted_at: .submitted_at
    }]
  ')
else
  PENDING_REVIEWS=$(echo "$REVIEWS_RESPONSE" | jq '
    [.[] | select(
      .state != "DISMISSED" and
      (.state != "COMMENTED" or (.body != "" and .body != null))
    ) | {
      user: .user.login,
      state: .state,
      body: .body,
      submitted_at: .submitted_at
    }]
  ')
fi

# Build final JSON output
FETCHED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --argjson pr_number "$PR_NUMBER" \
  --arg repo "${OWNER}/${REPO}" \
  --arg branch "$BRANCH" \
  --arg fetched_at "$FETCHED_AT" \
  --arg filter_user "$FILTER_USER" \
  --argjson unresolved_threads "$UNRESOLVED_THREADS" \
  --argjson pending_reviews "$PENDING_REVIEWS" \
  '{
    pr_number: $pr_number,
    repo: $repo,
    branch: $branch,
    fetched_at: $fetched_at,
    filter_user: (if $filter_user == "" then null else $filter_user end),
    unresolved_threads: $unresolved_threads,
    pending_reviews: $pending_reviews
  }' > "$OUTPUT_FILE"

echo "PR comments saved to: $OUTPUT_FILE"
echo ""
echo "Summary:"
echo "  PR #${PR_NUMBER} on ${OWNER}/${REPO}"
echo "  Branch: ${BRANCH}"
echo "  Unresolved threads: $(echo "$UNRESOLVED_THREADS" | jq 'length')"
echo "  Reviews: $(echo "$PENDING_REVIEWS" | jq 'length')"
if [ -n "$FILTER_USER" ]; then
  echo "  Filtered by user: ${FILTER_USER}"
fi
