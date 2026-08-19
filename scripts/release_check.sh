#!/usr/bin/env bash
# Run the complete local preflight against the committed tree that will be tagged.
set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "Usage: $0" >&2
  exit 2
fi

cd "$(dirname "$0")/.."

if [ -n "$(git status --porcelain)" ]; then
  echo "Release check requires a clean worktree:" >&2
  git status --short >&2
  exit 1
fi

run() {
  printf '\n==> %s\n' "$*"
  "$@"
}

run git diff --check
run scripts/check_versions.sh
run scripts/verify_plugins.sh
run bash test/render_profile_test.sh
run bash test/profile_contract_test.sh
run bash test/plugin_payload_test.sh

if [ "${_RAILS_ENGINEER_RELEASE_CHECK_UNDER_TEST:-}" != "1" ]; then
  run env _RAILS_ENGINEER_RELEASE_CHECK_UNDER_TEST=1 bash test/release_check_test.sh
fi

version=$(jq -r '.metadata.version' .claude-plugin/marketplace.json)
printf '\nRelease candidate v%s passed.\n' "$version"
printf 'Create the tag with: git tag v%s\n' "$version"
