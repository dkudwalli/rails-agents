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

declare -A choices=(
  [architecture]='layered rich-models'
  [testing]='rspec minitest'
  [css]='tailwind plain'
  [views]='viewcomponent erb-partials'
  [database]='postgres sqlite mysql'
  [ids]='uuidv7 integer'
  [authorization]='pundit scoped-model'
  [authentication]='secure-password session-record'
  [runtime]='solid redis-resque'
  [assets]='importmap node-bundler'
  [tenancy]='single multi'
  [deployment]='kamal docker-procfile'
  [workflow]='sdd conventional'
  [app_kind]='new existing'
)

declare -A values=()
divergences=()
reason=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --divergence)
      [[ $# -ge 2 && -n "$2" ]] || fail 'Missing value for --divergence'
      divergences+=("$2")
      shift 2
      ;;
    --reason)
      [[ $# -ge 2 && -n "$2" ]] || fail 'Missing value for --reason'
      reason="$2"
      shift 2
      ;;
    --architecture|--testing|--css|--views|--database|--ids|--authorization|--authentication|--runtime|--assets|--tenancy|--deployment|--workflow|--app-kind)
      [[ $# -ge 2 && -n "$2" ]] || fail "Missing value for $1"
      key=${1#--}
      key=${key//-/_}
      values["$key"]="$2"
      shift 2
      ;;
    *) usage ;;
  esac
done

for key in architecture testing css views database ids authorization authentication runtime assets tenancy deployment workflow app_kind; do
  option="--${key//_/-}"
  [[ -v "values[$key]" ]] || fail "Missing required option: $option"
  valid=false
  for candidate in ${choices[$key]}; do
    if [[ "${values[$key]}" == "$candidate" ]]; then
      valid=true
      break
    fi
  done
  "$valid" || fail "Invalid value for $option: ${values[$key]}"
done

[[ -n "$reason" ]] || fail 'Missing required option: --reason'

source='selected for a new application'
if [[ "${values[app_kind]}" == 'existing' ]]; then
  source='detected from the existing application'
fi

profile=$(cat <<EOF
<!-- rails-engineer:profile:start -->
## Rails Engineer Profile

Architecture: ${values[architecture]}
Testing: ${values[testing]}
CSS: ${values[css]}
Views: ${values[views]}
Database: ${values[database]}
IDs: ${values[ids]}
Authorization: ${values[authorization]}
Authentication: ${values[authentication]}
Runtime: ${values[runtime]}
Assets: ${values[assets]}
Tenancy: ${values[tenancy]}
Deployment: ${values[deployment]}
Workflow: ${values[workflow]}
Application kind: ${values[app_kind]}
Source: ${source}
Rationale: ${reason}

## Deliberate divergences
EOF
)

if [[ ${#divergences[@]} -eq 0 ]]; then
  profile+=$'\n- None recorded.'
else
  for divergence in "${divergences[@]}"; do
    profile+=$'\n- '"$divergence"
  done
fi

profile+=$(cat <<'EOF'


## Profile-first instruction

Read this profile before proposing implementation changes. A recorded deliberate divergence is a
decision, not migration work.
<!-- rails-engineer:profile:end -->
EOF
)

input=$(cat)
start='<!-- rails-engineer:profile:start -->'
end='<!-- rails-engineer:profile:end -->'
start_count=$(grep -Fxc "$start" <<<"$input" || true)
end_count=$(grep -Fxc "$end" <<<"$input" || true)

if [[ "$start_count" -eq 0 && "$end_count" -eq 0 ]]; then
  if [[ -n "$input" ]]; then
    printf '%s\n\n%s\n' "$input" "$profile"
  else
    printf '%s\n' "$profile"
  fi
elif [[ "$start_count" -eq 1 && "$end_count" -eq 1 ]]; then
  before=${input%%"$start"*}
  remainder=${input#*"$end"}
  printf '%s%s%s\n' "$before" "$profile" "$remainder"
else
  fail 'Malformed managed profile section'
fi
