#!/usr/bin/env bash
# Assert that the single released plugin's version agrees across its manifests.
# See AGENTS.md § Releasing. Exits non-zero and prints each path on disagreement.
set -euo pipefail

cd "$(dirname "$0")/.."

PACK="rails-engineer"

jq -e '
  (.plugins | length) == 1 and
  .plugins[0].name == "rails-engineer" and
  .plugins[0].source == "./rails-engineer"
' .claude-plugin/marketplace.json >/dev/null

versions=$(
  jq -r '.metadata.version | "\(.)\t.claude-plugin/marketplace.json (metadata)"' .claude-plugin/marketplace.json
  jq -r '.plugins[0].version | "\(.)\t.claude-plugin/marketplace.json (rails-engineer)"' .claude-plugin/marketplace.json
  jq -r --arg f "$PACK/.claude-plugin/plugin.json" '"\(.version)\t\($f)"' "$PACK/.claude-plugin/plugin.json"
  jq -r --arg f "$PACK/.codex-plugin/plugin.json" '"\(.version)\t\($f)"' "$PACK/.codex-plugin/plugin.json"
)

if [ "$(cut -f1 <<<"$versions" | sort -u | wc -l | tr -d ' ')" -ne 1 ]; then
  echo "Version mismatch:" >&2
  column -t -s$'\t' <<<"$versions" >&2
  exit 1
fi

echo "All manifests at $(cut -f1 <<<"$versions" | head -1)"
