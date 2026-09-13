#!/usr/bin/env bash
# Sync watches defined in watches.yaml to changedetection.io via its REST API.
#
# Usage:
#   ./scripts/sync-watches.sh
#
# Environment:
#   CD_BASE_URL   changedetection.io base URL (default http://127.0.0.1:5050)
#   CD_API_KEY    API key (Settings > API in the web UI)

set -euo pipefail

BASE_URL="${CD_BASE_URL:-http://127.0.0.1:5050}"
API_KEY="${CD_API_KEY:?Set CD_API_KEY}"
YAML_FILE="$(cd "$(dirname "$0")/.." && pwd)/watches.yaml"

if ! command -v yq >/dev/null 2>&1; then
  echo "error: yq is required (brew install yq)" >&2
  exit 1
fi

api() {
  local method="$1" path="$2"; shift 2
  curl -sS -X "$method" "$BASE_URL/api/v1$path" \
    -H "x-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    "$@"
}

count=$(yq '.watches | length' "$YAML_FILE")
echo "Syncing $count watches from watches.yaml -> $BASE_URL"

for i in $(seq 0 $((count - 1))); do
  url=$(yq ".watches[$i].url" "$YAML_FILE")
  title=$(yq -r ".watches[$i].title // \"\"" "$YAML_FILE")
  tag=$(yq -r ".watches[$i].tag // \"\"" "$YAML_FILE")
  interval_json=$(yq -o=json ".watches[$i].time_between_check // {\"hours\": 6}" "$YAML_FILE")

  existing=$(api GET "/watch" | jq -r --arg url "$url" \
    'to_entries[] | select(.value.url == $url) | .key' | head -1)

  body=$(jq -n --arg url "$url" --arg title "$title" --arg tag "$tag" \
    --argjson interval "$interval_json" \
    '{url: $url, title: $title, tags: [$tag], time_between_check: $interval} | with_entries(select(.value != "" and .value != []))')

  if [ -n "$existing" ]; then
    api PUT "/watch/$existing" -d "$body" >/dev/null
    echo "updated: $url ($existing)"
  else
    uuid=$(api POST "/watch" -d "$body")
    echo "created: $url ($uuid)"
  fi
done

# Delete watches that exist on the server but not in watches.yaml
api GET "/watch" | jq -r 'to_entries[] | "\(.key)\t\(.value.url)"' | while IFS=$'\t' read -r uuid remote_url; do
  if ! yq -r '.watches[].url' "$YAML_FILE" | grep -qxF "$remote_url"; then
    api DELETE "/watch/$uuid" >/dev/null
    echo "deleted: $remote_url ($uuid)"
  fi
done

echo "Done."
