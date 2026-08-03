---
name: tooling-ci-deploy
description: >-
  Sets up rerunnable bin/setup, config/ci.rb as ordered shell steps, RuboCop
  omakase, a multi-stage Dockerfile, deployment, and production observability.
  Use when configuring CI, writing setup scripts, containerizing, deploying,
  configuring initializers or environments, adding health checks or logging, or
  when user mentions CI, Docker, Kamal, deploy, bin/setup, RuboCop config, or
  operability.
  WHEN NOT: Writing application code (use the pattern skills), database schema
  design (use migration-patterns), or test authoring (use testing-patterns).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+, Docker
---

# Tooling, CI, Deploy & Operability

Configuration is executable product code. Treat `bin/setup`, `config/ci.rb`, and the Dockerfile as
things that get read, tested, and reviewed — not as scaffolding.

## bin/setup is the one way in

It must be safe to re-run. Destructive work sits behind an explicit flag.

```bash
#!/usr/bin/env bash
set -e

bundle check || bundle install
bin/rails db:prepare                 # create or migrate, whichever is needed

if [[ "$1" == "--reset" ]]; then
  bin/rails db:reset                 # only with the flag
fi

bin/rails log:clear tmp:clear
```

Setup and seed data are product code. Give `bin/setup` a test.

Seeds live as real Ruby in `db/seeds/`.

## CI is ordered shell steps in config/ci.rb

Readable top to bottom, in a fixed order: setup → style → security → tests → signoff. Force system
tests to run serially.

```ruby
# config/ci.rb -- run with bin/ci
SYSTEM_TEST_ENV = "PARALLEL_WORKERS=1"   # system tests can't run reliably in parallel

CI.run do
  step "Setup",                     "bin/setup --skip-server"
  step "Style: Ruby",               "bin/rubocop -f simple"
  step "Security: Gem audit",       "bin/bundler-audit check --update"
  step "Security: Importmap audit", "bin/importmap audit"
  step "Security: Brakeman audit",  "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Security: Gitleaks audit",  "bin/gitleaks-audit"
  step "Tests",                     "bin/rails test"
  step "Tests: System",             "#{SYSTEM_TEST_ENV} bin/rails test:system"

  if success?
    step "Signoff: All systems go.", "gh signoff"
  else
    failure "Signoff: CI failed.", "Fix the issues and try again."
  end
end
```

All four security scanners run on **every** CI run, with `--exit-on-warn`. Triage Brakeman findings
into a checked-in ignore file — never by disabling the tool. Make a green run a merge gate.

> `ActiveSupport::ContinuousIntegration` is an edge-Rails feature. Verify it exists in your release,
> or write the same ordered steps in whatever runner you have.

## RuboCop: omakase plus your actual decisions

```yaml
# .rubocop.yml -- keep it around 20 lines
inherit_gem:
  rubocop-rails-omakase: rubocop.yml

AllCops:
  Exclude:
    - db/schema.rb
    - db/migrate/**/*
```

`rubocop-rails-omakase` is not a starting point to customise heavily — it is the baseline. Add a local
rule only for a decision the team actually made. Note that omakase is also what makes the
indent-under-`private` style pass; stock RuboCop or Standard will fight the whole codebase.

## A boring multi-stage container

```dockerfile
FROM ruby:3.4-slim AS base
WORKDIR /rails
ENV RAILS_ENV=production BUNDLE_WITHOUT=development

FROM base AS build
# ... build gems and precompile assets in a throwaway stage
RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile

FROM base
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails
USER 1000:1000

CMD ["./bin/thrust", "./bin/rails", "server"]
```

- Build gems and assets in a throwaway stage; remove caches
- `SECRET_KEY_BASE_DUMMY=1` so no real secret is needed to precompile — and none is baked in
- Run as a non-root user
- Thruster in front of Puma; no separate Nginx layer

## Deployment follows the profile

**Fizzy profile:** Kamal + Docker. Commit `config/deploy.yml`, keep secrets outside Git, declare and
back up the persistent storage volume, and bridge fingerprinted assets across deploys.

**ONCE-compatible profile:** a Docker image plus a `Procfile` — the whole production topology is a
handful of lines (web, queue worker, and whatever backing service the profile requires).

Do not combine the two. Running Procfile workers alongside `SOLID_QUEUE_IN_PUMA` is named explicitly
as a thing not to do.

## Configuration and lifecycle

- Set one baseline in `config/application.rb`: framework-version defaults, generator defaults,
  `autoload_lib ignore:`. Runtime policy goes in the environment file
- **Do not copy another app's `load_defaults` version.** The three source applications sit on
  different ones
- Keep initializers narrow and lifecycle-aware — one responsibility per file, using
  `ActiveSupport.on_load` / `to_prepare` / `after_initialize` rather than depending on load order
- Put deployment switches at the config boundary; business code should not consult `ENV` repeatedly
- Establish request context at the edge: populate `Current` once at the request boundary, keep its
  attributes explicit, clear or serialize it across job and Cable boundaries. `Current` is never a
  place for data that must survive the request
- Derive URL options from one `BASE_URL`. Add a named input when a *deployer* — not a Ruby caller —
  has to choose the value. Do not add `config.x` for a value with one caller
- Production policy is boring and explicit: no reloading, eager load, caching on, stdout logging

## Operability without an agent

- **stdout logs, tagged with `:request_id`**, level configurable at deploy time
- Global parameter filtering covering personal data and user content, not only secrets
- Tenant/user context attached to error reports only
- A cheap `/up` health check
- Bound expensive work and preserve its recovery path: time, byte, batch, and retention limits sit
  next to the operation; persist enough state to resume or reconcile; use database-level counters and
  locks for contested totals

**Add monitoring infrastructure only when stdout logs, error reports, job visibility, and a health
endpoint no longer answer the operational question.**

## Boundaries

- **Always:** Keep `bin/setup` rerunnable with destructive work behind `--reset`, run style and all
  security scanners on every CI run, run system tests serially, build a multi-stage image with a
  non-root user, commit deploy config, keep secrets out of Git, declare durable storage, log to
  stdout with request tags, ship a `/up` endpoint
- **Ask first:** Before adding a local RuboCop rule, before adding a monitoring service, before
  introducing a second deployment mechanism
- **Never:** Bake a secret into an image, run as root, disable a security scanner instead of triaging
  its findings, mix Kamal and Procfile deployment models, copy another app's `load_defaults` version,
  add `config.x` for a single caller

See [`12-tooling-ci-deploy.md`](../../docs/37signals-playbook/12-tooling-ci-deploy.md),
[`16-configuration-lifecycle.md`](../../docs/37signals-playbook/16-configuration-lifecycle.md), and
[`20-performance-operability.md`](../../docs/37signals-playbook/20-performance-operability.md).
