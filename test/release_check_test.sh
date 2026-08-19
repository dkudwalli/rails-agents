#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

failures=0

fail() {
  echo "FAIL: $1" >&2
  failures=$((failures + 1))
}

assert_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

fixture() {
  local path="$TMPDIR/$1"
  mkdir "$path"

  # Exercise the exact release payload without copying the source repository's
  # Git metadata into the fixture. A copied .git directory points at the
  # source worktree and makes a clean fixture look dirty or outside Git.
  git -C "$ROOT" archive --format=tar HEAD | tar -x -C "$path"
  git -C "$path" init -q
  git -C "$path" add -A
  git -C "$path" -c user.name='Release Check Test' -c user.email='release-check@example.test' commit -qm fixture
  printf '%s' "$path"
}

test_clean_fixture_passes() {
  local path output version
  path=$(fixture clean)
  version=$(jq -r '.metadata.version' "$path/.claude-plugin/marketplace.json")
  output=$(env _RAILS_ENGINEER_RELEASE_CHECK_UNDER_TEST=1 "$path/scripts/release_check.sh")

  assert_contains "$output" '==> bash test/profile_contract_test.sh'
  assert_contains "$output" "Release candidate v$version passed."
  assert_contains "$output" "Create the tag with: git tag v$version"
}

test_release_check_runs_its_contract_test() {
  local path output
  path=$(fixture runs-contract-test)
  # This is the outer release invocation. Nested invocations receive the
  # internal guard from release_check.sh, so this remains finite when the
  # contract test runs as part of a release check.
  output=$(env -u _RAILS_ENGINEER_RELEASE_CHECK_UNDER_TEST "$path/scripts/release_check.sh")

  assert_contains "$output" 'bash test/release_check_test.sh'
  assert_contains "$output" 'PASS: release check contract'
}

test_dirty_fixture_fails_before_checks() {
  local path output status
  path=$(fixture dirty)
  touch "$path/UNCOMMITTED_RELEASE_CHANGE"

  set +e
  output=$(env _RAILS_ENGINEER_RELEASE_CHECK_UNDER_TEST=1 "$path/scripts/release_check.sh" 2>&1)
  status=$?
  set -e

  [ "$status" -ne 0 ] || fail 'expected a dirty fixture to fail'
  assert_contains "$output" 'Release check requires a clean worktree:'
  assert_contains "$output" '?? UNCOMMITTED_RELEASE_CHANGE'
}

test_version_mismatch_fails() {
  local path manifest output status
  path=$(fixture version-mismatch)
  manifest="$path/rails-engineer/.codex-plugin/plugin.json"
  jq '.version = "9.9.9"' "$manifest" > "$manifest.tmp"
  mv "$manifest.tmp" "$manifest"
  git -C "$path" add rails-engineer/.codex-plugin/plugin.json
  git -C "$path" -c user.name='Release Check Test' -c user.email='release-check@example.test' commit -qm mismatch

  set +e
  output=$(env _RAILS_ENGINEER_RELEASE_CHECK_UNDER_TEST=1 "$path/scripts/release_check.sh" 2>&1)
  status=$?
  set -e

  [ "$status" -ne 0 ] || fail 'expected a version mismatch to fail'
  assert_contains "$output" 'Version mismatch:'
}

test_clean_fixture_passes
if [ "${_RAILS_ENGINEER_RELEASE_CHECK_UNDER_TEST:-}" != "1" ]; then
  test_release_check_runs_its_contract_test
fi
test_dirty_fixture_fails_before_checks
test_version_mismatch_fails

if [ "$failures" -gt 0 ]; then
  echo "FAIL: $failures assertion(s) failed" >&2
  exit 1
fi

echo 'PASS: release check contract'
