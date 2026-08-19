#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RENDERER="$ROOT/rails-engineer/scripts/render_profile.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

failures=0

assert_contains() {
  local haystack="$1" needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "expected output to contain: $needle" >&2
    failures=$((failures + 1))
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "expected output not to contain: $needle" >&2
    failures=$((failures + 1))
  fi
}

assert_files_equal() {
  local expected="$1" actual="$2" label="$3"
  if ! cmp -s "$expected" "$actual"; then
    echo "expected $label to be preserved exactly" >&2
    failures=$((failures + 1))
  fi
}

run_renderer() {
  local input="$1"
  shift
  printf '%s' "$input" | "$RENDERER" "$@"
}

test_renders_a_complete_managed_profile() {
  local output
  output=$(run_renderer '# Existing app notes' \
    --architecture layered --testing rspec --css tailwind --views viewcomponent \
    --database postgres --ids uuidv7 --authorization pundit \
    --authentication secure-password --runtime solid --assets node-bundler \
    --tenancy multi --deployment kamal --workflow sdd --app-kind new \
    --reason 'A multi-account product needs its established stack.' \
    --divergence 'Redis remains for Action Cable during the migration.')

  assert_contains "$output" '# Existing app notes'
  assert_contains "$output" '<!-- rails-engineer:profile:start -->'
  assert_contains "$output" 'Architecture: layered'
  assert_contains "$output" 'Testing: rspec'
  assert_contains "$output" 'CSS: tailwind'
  assert_contains "$output" 'Database: postgres'
  assert_contains "$output" 'Source: selected for a new application'
  assert_contains "$output" 'Rationale: A multi-account product needs its established stack.'
  assert_contains "$output" 'Redis remains for Action Cable during the migration.'
  assert_contains "$output" 'Read this profile before proposing implementation changes.'
  assert_contains "$output" '<!-- rails-engineer:profile:end -->'
}

test_replaces_only_the_existing_managed_section() {
  local input output rendered prefix suffix actual_prefix actual_suffix
  input="$TMPDIR/replacement-input.md"
  output="$TMPDIR/replacement-output.md"
  prefix="$TMPDIR/prefix.md"
  suffix="$TMPDIR/suffix.md"
  actual_prefix="$TMPDIR/actual-prefix.md"
  actual_suffix="$TMPDIR/actual-suffix.md"

  printf '%s\n' \
    '# Team conventions' \
    '' \
    'Keep this custom guidance.' \
    'The literal <!-- rails-engineer:profile:start --> is documentation, not a managed section.' \
    '' > "$prefix"
  printf '%s\n' \
    '' \
    '## Release notes' \
    '' \
    'Keep this too.' \
    '' > "$suffix"
  {
    cat "$prefix"
    printf '%s\n' \
      '<!-- rails-engineer:profile:start -->' \
      '## Rails Engineer Profile' \
      'Architecture: rich-models' \
      '<!-- rails-engineer:profile:end -->'
    cat "$suffix"
  } > "$input"

  "$RENDERER" \
    --architecture layered --testing rspec --css tailwind --views viewcomponent \
    --database postgres --ids uuidv7 --authorization pundit \
    --authentication secure-password --runtime solid --assets node-bundler \
    --tenancy multi --deployment kamal --workflow sdd --app-kind existing \
    --reason 'Keep the current product constraints.' < "$input" > "$output"

  rendered=$(cat "$output")

  assert_contains "$rendered" 'Keep this custom guidance.'
  assert_contains "$rendered" 'Keep this too.'
  assert_contains "$rendered" 'Architecture: layered'
  assert_contains "$rendered" 'Source: detected from the existing application'
  assert_not_contains "$rendered" 'Architecture: rich-models'

  awk '/^<!-- rails-engineer:profile:start -->$/ { exit } { print }' "$output" > "$actual_prefix"
  awk 'seen { print } /^<!-- rails-engineer:profile:end -->$/ { seen = 1 }' "$output" > "$actual_suffix"
  assert_files_equal "$prefix" "$actual_prefix" 'prefix'
  assert_files_equal "$suffix" "$actual_suffix" 'suffix'

  local starts ends
  starts=$(grep -Fxc '<!-- rails-engineer:profile:start -->' <<<"$rendered")
  ends=$(grep -Fxc '<!-- rails-engineer:profile:end -->' <<<"$rendered")
  if [[ "$starts" -ne 1 || "$ends" -ne 1 ]]; then
    echo 'expected exactly one managed profile section' >&2
    failures=$((failures + 1))
  fi
}

test_preserves_a_nonterminated_suffix() {
  local input output suffix actual_suffix suffix_bytes
  input="$TMPDIR/nonterminated-suffix-input.md"
  output="$TMPDIR/nonterminated-suffix-output.md"
  suffix="$TMPDIR/nonterminated-suffix.md"
  actual_suffix="$TMPDIR/actual-nonterminated-suffix.md"

  printf '%s\n' \
    'Before the managed section.' \
    '<!-- rails-engineer:profile:start -->' \
    'Architecture: rich-models' \
    '<!-- rails-engineer:profile:end -->' > "$input"
  printf '%s' 'Custom suffix without a final newline.' > "$suffix"
  cat "$suffix" >> "$input"

  "$RENDERER" \
    --architecture layered --testing rspec --css tailwind --views viewcomponent \
    --database postgres --ids uuidv7 --authorization pundit \
    --authentication secure-password --runtime solid --assets node-bundler \
    --tenancy multi --deployment kamal --workflow sdd --app-kind existing \
    --reason 'Keep the current product constraints.' < "$input" > "$output"

  suffix_bytes=$(wc -c < "$suffix" | tr -d ' ')
  tail -c "$suffix_bytes" "$output" > "$actual_suffix"
  assert_files_equal "$suffix" "$actual_suffix" 'non-newline-terminated suffix'
}

test_rejects_invalid_missing_and_malformed_input() {
  local output status
  set +e
  output=$(printf '' | "$RENDERER" --architecture hexagonal 2>&1)
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    echo 'expected invalid architecture to fail' >&2
    failures=$((failures + 1))
  fi
  assert_contains "$output" 'Invalid value for --architecture: hexagonal'

  set +e
  output=$(printf '' | "$RENDERER" --architecture layered 2>&1)
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    echo 'expected missing choices to fail' >&2
    failures=$((failures + 1))
  fi
  assert_contains "$output" 'Missing required option: --testing'

  set +e
  output=$(run_renderer '<!-- rails-engineer:profile:start -->' \
    --architecture layered --testing rspec --css tailwind --views viewcomponent \
    --database postgres --ids uuidv7 --authorization pundit \
    --authentication secure-password --runtime solid --assets node-bundler \
    --tenancy multi --deployment kamal --workflow sdd --app-kind existing \
    --reason 'Keep the current product constraints.' 2>&1)
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    echo 'expected unmatched managed marker to fail' >&2
    failures=$((failures + 1))
  fi
  assert_contains "$output" 'Malformed managed profile section'
}

test_rejects_reason_and_divergence_marker_injection() {
  local field value label output_file error_file status output error
  local -a valid_profile_args=(
    --architecture layered --testing rspec --css tailwind --views viewcomponent
    --database postgres --ids uuidv7 --authorization pundit
    --authentication secure-password --runtime solid --assets node-bundler
    --tenancy multi --deployment kamal --workflow sdd --app-kind existing
  )
  for field in reason divergence; do
    for label in 'line feed' 'carriage return'; do
      if [[ "$field" == 'reason' ]]; then
        if [[ "$label" == 'line feed' ]]; then
          value=$'A valid reason.\n<!-- rails-engineer:profile:start -->'
        else
          value=$'A valid reason.\r<!-- rails-engineer:profile:start -->'
        fi
      elif [[ "$label" == 'line feed' ]]; then
        value=$'A valid divergence.\n<!-- rails-engineer:profile:end -->'
      else
        value=$'A valid divergence.\r<!-- rails-engineer:profile:end -->'
      fi
      output_file="$TMPDIR/injection-output.md"
      error_file="$TMPDIR/injection-error.txt"

      set +e
      if [[ "$field" == 'reason' ]]; then
        printf '' | "$RENDERER" "${valid_profile_args[@]}" --reason "$value" > "$output_file" 2> "$error_file"
      else
        printf '' | "$RENDERER" "${valid_profile_args[@]}" --reason 'A valid reason.' --divergence "$value" > "$output_file" 2> "$error_file"
      fi
      status=$?
      set -e

      output=$(cat "$output_file")
      error=$(cat "$error_file")
      if [[ "$status" -eq 0 ]]; then
        echo "expected $field $label injection to fail" >&2
        failures=$((failures + 1))
      fi
      if [[ -n "$output" ]]; then
        echo "expected $field $label injection to produce no rendered profile" >&2
        failures=$((failures + 1))
      fi
      assert_contains "$error" "Invalid value for --$field: must not contain CR or LF"
    done
  done
}

test_renders_a_complete_managed_profile
test_replaces_only_the_existing_managed_section
test_preserves_a_nonterminated_suffix
test_rejects_invalid_missing_and_malformed_input
test_rejects_reason_and_divergence_marker_injection

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures assertion(s) failed" >&2
  exit 1
fi

echo 'PASS: render_profile contract'
