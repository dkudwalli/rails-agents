#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RENDERER="$ROOT/rails-engineer/scripts/render_profile.sh"
# shellcheck source=../rails-engineer/scripts/profile_contract.sh
. "$ROOT/rails-engineer/scripts/profile_contract.sh"

failures=0

assert_contains() {
  local haystack="$1" needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "expected output to contain: $needle" >&2
    failures=$((failures + 1))
  fi
}

profile_label_for() {
  case "$1" in
    architecture) printf '%s' 'Architecture' ;;
    testing) printf '%s' 'Testing' ;;
    css) printf '%s' 'CSS' ;;
    views) printf '%s' 'Views' ;;
    database) printf '%s' 'Database' ;;
    ids) printf '%s' 'IDs' ;;
    authorization) printf '%s' 'Authorization' ;;
    authentication) printf '%s' 'Authentication' ;;
    runtime) printf '%s' 'Runtime' ;;
    assets) printf '%s' 'Assets' ;;
    tenancy) printf '%s' 'Tenancy' ;;
    deployment) printf '%s' 'Deployment' ;;
    workflow) printf '%s' 'Workflow' ;;
    app_kind) printf '%s' 'Application kind' ;;
  esac
}

render_with_selection() {
  local selected_field="$1" selected_value="$2" field value output
  local -a args=()

  for field in "${PROFILE_FIELDS[@]}"; do
    value=$(profile_allowed_values "$field")
    value=${value%% *}
    if [[ "$field" == "$selected_field" ]]; then
      value="$selected_value"
    fi
    args+=("--${field//_/-}" "$value")
  done

  if ! output=$(printf '' | "$RENDERER" "${args[@]}" --reason 'Contract coverage.'); then
    echo "expected $selected_field=$selected_value to render" >&2
    failures=$((failures + 1))
    return
  fi
  assert_contains "$output" "$(profile_label_for "$selected_field"): $selected_value"
}

test_every_allowed_value_renders() {
  local field value
  for field in "${PROFILE_FIELDS[@]}"; do
    for value in $(profile_allowed_values "$field"); do
      render_with_selection "$field" "$value"
    done
  done
}

test_documented_starter_stacks_render() {
  local output

  output=$(printf '' | "$RENDERER" \
    --architecture layered --testing rspec --css tailwind --views viewcomponent \
    --database postgres --ids uuidv7 --authorization pundit \
    --authentication secure-password --runtime solid --assets node-bundler \
    --tenancy multi --deployment kamal --workflow conventional --app-kind new \
    --reason 'Layered starter stack.')
  assert_contains "$output" 'Architecture: layered'
  assert_contains "$output" 'Workflow: conventional'

  output=$(printf '' | "$RENDERER" \
    --architecture rich-models --testing minitest --css plain --views erb-partials \
    --database sqlite --ids uuidv7 --authorization scoped-model \
    --authentication session-record --runtime solid --assets importmap \
    --tenancy multi --deployment kamal --workflow conventional --app-kind new \
    --reason 'Rich Models Fizzy-style starter stack.')
  assert_contains "$output" 'Architecture: rich-models'
  assert_contains "$output" 'IDs: uuidv7'
  assert_contains "$output" 'Runtime: solid'

  output=$(printf '' | "$RENDERER" \
    --architecture rich-models --testing minitest --css plain --views erb-partials \
    --database sqlite --ids integer --authorization scoped-model \
    --authentication session-record --runtime redis-resque --assets importmap \
    --tenancy single --deployment docker-procfile --workflow conventional --app-kind new \
    --reason 'Rich Models ONCE-compatible starter stack.')
  assert_contains "$output" 'Architecture: rich-models'
  assert_contains "$output" 'IDs: integer'
  assert_contains "$output" 'Runtime: redis-resque'
  assert_contains "$output" 'Deployment: docker-procfile'
}

test_every_allowed_value_renders
test_documented_starter_stacks_render

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures assertion(s) failed" >&2
  exit 1
fi

echo 'PASS: profile contract'
