#!/usr/bin/env bash
# Create a Forgejo release for $TAG, using the annotated tag message as notes.
set -euo pipefail
: "${TAG:?}" "${TOKEN:?}" "${API:?}"

# checkout may fetch the tag without its annotation; fetch the real tag object
git fetch --force origin "refs/tags/$TAG:refs/tags/$TAG"
notes=$(git tag -l --format='%(contents)' "$TAG")

jq -n --arg tag "$TAG" --arg body "$notes" \
  '{tag_name: $tag, name: $tag, body: $body, draft: true}' |
  curl -fsS -X POST "$API/releases" \
    -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    --data @-
