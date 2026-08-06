---
name: rails-onboard
description: >-
  Detects and records a Rails application's selected architecture and stack in a managed AGENTS.md
  profile. Use after installing Rails Engineer, when starting a Rails application, or when an
  existing application's conventions need confirmation. WHEN NOT: applying a known profile to a
  single feature; use the matching rails-* router instead.
user-invocable: true
---

# Onboard a Rails application

Create or update the profile before applying any convention. This is a guided, non-destructive
decision capture, not a dependency installer or migration tool.

## 1. Find evidence, then ask one question at a time

If `AGENTS.md` already has a complete managed Rails Engineer profile, read it first. Compare it to
the repository and ask for confirmation or a changed value one choice at a time. Never silently
replace a recorded choice.

For an existing app, inspect these project signals before asking. They are evidence, not authority:

| Choice | Look for |
|---|---|
| architecture | `app/services/`, `app/queries/`, `app/policies/`, `app/models/*/` concerns |
| testing | `spec/`, `rspec`/`factory_bot` in Gemfile; `test/`, fixtures, Minitest |
| CSS | `tailwind.config.*`, `tailwindcss-rails`; `app/assets/stylesheets/*.css` |
| views | `app/components/` and ViewComponent; ERB partials under `app/views/` |
| database and IDs | `config/database.yml`, `db/schema.rb`, and migration primary-key types |
| authorization and authentication | Pundit policies; scoped current-account lookups; `has_secure_password`; `Session` model |
| runtime | Solid Queue/Cache/Cable configuration; Redis, Resque, or a Procfile |
| assets | `config/importmap.rb`; `package.json`, bundler configuration |
| tenancy | `Account`/`Current.account`, account-scoped routes and migrations |
| deployment | `config/deploy.yml`; `Dockerfile` and `Procfile` |
| workflow | `.specify/`, existing specs/plans, or the team's conventional issue/PR process |

Ask exactly one question, wait for its answer, record it, then ask the next. For a new app, explain
the two or three allowed values and ask in this order: architecture, testing, CSS, views, database,
IDs, authorization, authentication, runtime, assets, tenancy, deployment, workflow. Ask whether
the app is `new` or `existing`, then ask for one concise rationale.

## 2. Handle mixed choices explicitly

Warn before accepting a combination that crosses the default profiles: layered normally aligns with
RSpec, Tailwind, ViewComponent, and Pundit; rich-models normally aligns with Minitest, plain CSS,
ERB partials, and scoped-model authorization. Also warn when a selection conflicts with detected
application files. Do not reject it: ask for the reason it must remain, repeat the wording back,
and record it as a `--divergence`. A recorded divergence is not a request to install, remove, or
migrate anything.

## 3. Preview and confirm the exact write

Build the renderer arguments from the answers. Read the current `AGENTS.md` if it exists; otherwise
use an empty input. Render to a temporary file, show the complete managed section and say whether it
will append a new section or replace the existing markers. Ask for explicit confirmation before any
write. On reruns, show a concise comparison of changed fields before that confirmation.

Use the absolute directory from which this `SKILL.md` was loaded. The trailing semicolon is required:

```bash
SKILL_DIR="<absolute path to the loaded rails-onboard skill directory>"; \
PROFILE_RENDERER="$SKILL_DIR/../../scripts/render_profile.sh"; \
INPUT="AGENTS.md"; OUTPUT="$(mktemp)"; \
if [ -f "$INPUT" ]; then "$PROFILE_RENDERER" < "$INPUT" > "$OUTPUT" --architecture <value> --testing <value> --css <value> --views <value> --database <value> --ids <value> --authorization <value> --authentication <value> --runtime <value> --assets <value> --tenancy <value> --deployment <value> --workflow <value> --app-kind <new|existing> --reason "<rationale>"; else "$PROFILE_RENDERER" < /dev/null > "$OUTPUT" --architecture <value> --testing <value> --css <value> --views <value> --database <value> --ids <value> --authorization <value> --authentication <value> --runtime <value> --assets <value> --tenancy <value> --deployment <value> --workflow <value> --app-kind <new|existing> --reason "<rationale>"; fi
```

Add one `--divergence "<reason>"` for each recorded mixed choice. After confirmation, atomically
replace `AGENTS.md` with `mv "$OUTPUT" "$INPUT"`. If the renderer rejects malformed markers, stop
and ask the user to resolve them; never overwrite user content. Do not run dependency installers,
generators, migrations, or configuration changes.
