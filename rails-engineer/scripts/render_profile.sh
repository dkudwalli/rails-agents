#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --architecture <layered|rich-models> ..." >&2
  exit 2
}

fail() {
  echo "$1" >&2
  exit 2
}

valid_choice() {
  local value="$1" allowed="$2" candidate
  for candidate in $allowed; do
    [ "$value" = "$candidate" ] && return 0
  done
  return 1
}

value_for() {
  case "$1" in
    architecture) printf '%s' "$architecture" ;;
    testing) printf '%s' "$testing" ;;
    css) printf '%s' "$css" ;;
    views) printf '%s' "$views" ;;
    database) printf '%s' "$database" ;;
    ids) printf '%s' "$ids" ;;
    authorization) printf '%s' "$authorization" ;;
    authentication) printf '%s' "$authentication" ;;
    runtime) printf '%s' "$runtime" ;;
    assets) printf '%s' "$assets" ;;
    tenancy) printf '%s' "$tenancy" ;;
    deployment) printf '%s' "$deployment" ;;
    workflow) printf '%s' "$workflow" ;;
    app_kind) printf '%s' "$app_kind" ;;
  esac
}

allowed_for() {
  case "$1" in
    architecture) printf '%s' 'layered rich-models' ;;
    testing) printf '%s' 'rspec minitest' ;;
    css) printf '%s' 'tailwind plain' ;;
    views) printf '%s' 'viewcomponent erb-partials' ;;
    database) printf '%s' 'postgres sqlite mysql' ;;
    ids) printf '%s' 'uuidv7 integer' ;;
    authorization) printf '%s' 'pundit scoped-model' ;;
    authentication) printf '%s' 'secure-password session-record' ;;
    runtime) printf '%s' 'solid redis-resque' ;;
    assets) printf '%s' 'importmap node-bundler' ;;
    tenancy) printf '%s' 'single multi' ;;
    deployment) printf '%s' 'kamal docker-procfile' ;;
    workflow) printf '%s' 'sdd conventional' ;;
    app_kind) printf '%s' 'new existing' ;;
  esac
}

architecture=''
testing=''
css=''
views=''
database=''
ids=''
authorization=''
authentication=''
runtime=''
assets=''
tenancy=''
deployment=''
workflow=''
app_kind=''
reason=''
divergences=''

while [ "$#" -gt 0 ]; do
  case "$1" in
    --divergence)
      [ "$#" -ge 2 ] && [ -n "$2" ] || fail 'Missing value for --divergence'
      if [ -n "$divergences" ]; then
        divergences="${divergences}
$2"
      else
        divergences="$2"
      fi
      shift 2
      ;;
    --reason)
      [ "$#" -ge 2 ] && [ -n "$2" ] || fail 'Missing value for --reason'
      reason="$2"
      shift 2
      ;;
    --architecture|--testing|--css|--views|--database|--ids|--authorization|--authentication|--runtime|--assets|--tenancy|--deployment|--workflow|--app-kind)
      [ "$#" -ge 2 ] && [ -n "$2" ] || fail "Missing value for $1"
      option=${1#--}
      option=${option//-/_}
      case "$option" in
        architecture) architecture="$2" ;;
        testing) testing="$2" ;;
        css) css="$2" ;;
        views) views="$2" ;;
        database) database="$2" ;;
        ids) ids="$2" ;;
        authorization) authorization="$2" ;;
        authentication) authentication="$2" ;;
        runtime) runtime="$2" ;;
        assets) assets="$2" ;;
        tenancy) tenancy="$2" ;;
        deployment) deployment="$2" ;;
        workflow) workflow="$2" ;;
        app_kind) app_kind="$2" ;;
      esac
      shift 2
      ;;
    *) usage ;;
  esac
done

for key in architecture testing css views database ids authorization authentication runtime assets tenancy deployment workflow app_kind; do
  option="--${key//_/-}"
  value=$(value_for "$key")
  [ -n "$value" ] || fail "Missing required option: $option"
  valid_choice "$value" "$(allowed_for "$key")" || fail "Invalid value for $option: $value"
done

[ -n "$reason" ] || fail 'Missing required option: --reason'

source='selected for a new application'
if [ "$app_kind" = 'existing' ]; then
  source='detected from the existing application'
fi

input_file=$(mktemp "${TMPDIR:-/tmp}/rails-engineer-profile-input.XXXXXX")
profile_file=$(mktemp "${TMPDIR:-/tmp}/rails-engineer-profile-output.XXXXXX")
trap 'rm -f "$input_file" "$profile_file"' EXIT HUP INT TERM
cat > "$input_file"

cat > "$profile_file" <<EOF
<!-- rails-engineer:profile:start -->
## Rails Engineer Profile

Architecture: $architecture
Testing: $testing
CSS: $css
Views: $views
Database: $database
IDs: $ids
Authorization: $authorization
Authentication: $authentication
Runtime: $runtime
Assets: $assets
Tenancy: $tenancy
Deployment: $deployment
Workflow: $workflow
Application kind: $app_kind
Source: $source
Rationale: $reason

## Deliberate divergences
EOF

if [ -z "$divergences" ]; then
  printf '%s\n' '- None recorded.' >> "$profile_file"
else
  while IFS= read -r divergence || [ -n "$divergence" ]; do
    printf '%s\n' "- $divergence" >> "$profile_file"
  done <<EOF
$divergences
EOF
fi

cat >> "$profile_file" <<'EOF'

## Profile-first instruction

Read this profile before proposing implementation changes. A recorded deliberate divergence is a
decision, not migration work.
<!-- rails-engineer:profile:end -->
EOF

marker_state=$(LC_ALL=C awk '
  BEGIN { offset = 0 }
  $0 == "<!-- rails-engineer:profile:start -->" {
    if (inside || starts) invalid = 1
    inside = 1
    starts++
    start_offset = offset
    offset += length($0) + 1
    next
  }
  $0 == "<!-- rails-engineer:profile:end -->" {
    if (!inside || ends) invalid = 1
    inside = 0
    ends++
    end_offset = offset + length($0) + 1
    offset += length($0) + 1
    next
  }
  { offset += length($0) + 1 }
  END {
    if (invalid || inside || starts != ends || starts > 1) print "malformed"
    else if (starts == 1) print "managed", start_offset, end_offset
    else print "none"
  }
' "$input_file")

case "$marker_state" in
  none)
    if [ -s "$input_file" ]; then
      cat "$input_file"
      printf '\n\n'
    fi
    cat "$profile_file"
    ;;
  managed\ *)
    set -- $marker_state
    dd if="$input_file" bs=1 count="$2" 2>/dev/null
    cat "$profile_file"
    dd if="$input_file" bs=1 skip="$3" 2>/dev/null
    ;;
  *) fail 'Malformed managed profile section' ;;
esac
