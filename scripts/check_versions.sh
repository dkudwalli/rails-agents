#!/usr/bin/env bash
# Assert the version string agrees across every manifest that carries one.
# See AGENTS.md § Releasing. Exits non-zero and prints each path on disagreement.
set -euo pipefail

cd "$(dirname "$0")/.."

versions=$(
  jq -r '.metadata.version           | "\(.)\t.claude-plugin/marketplace.json (metadata)"'   .claude-plugin/marketplace.json
  jq -r '.plugins[] | "\(.version)\t.claude-plugin/marketplace.json (\(.name))"'             .claude-plugin/marketplace.json
  for f in rails-*/.claude-plugin/plugin.json rails-*/.codex-plugin/plugin.json; do
    jq -r --arg f "$f" '"\(.version)\t\($f)"' "$f"
  done
)

if [ "$(cut -f1 <<<"$versions" | sort -u | wc -l)" -ne 1 ]; then
  echo "Version mismatch:" >&2
  column -t -s$'\t' <<<"$versions" >&2
  exit 1
fi

echo "All manifests at $(cut -f1 <<<"$versions" | head -1)"
