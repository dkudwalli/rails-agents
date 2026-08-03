# 12 — Tooling, CI & deployment

The operating model is deliberately ordinary: one setup command, one ordered CI script, one
multi-stage Dockerfile, and as few runtime services as the app needs.

---

## Make `bin/setup` safe to re-run

Use `bin/setup` as the one way to get a checkout running. It installs dependencies, prepares the
database, clears disposable state, and leaves the developer with a working app. Prefer idempotent
operations such as `bundle check || bundle install` and `rails db:prepare`.

`writebook/bin/setup:8-23`:

```bash
announce "Installing dependencies"
gem install bundler --conservative
bundle check || bundle install

announce "Preparing database"
if [[ $* == *--reset* ]]; then
  rails db:reset
else
  rails db:prepare
fi

announce "Removing old logs and tempfiles"
rails log:clear tmp:clear
```

`once-campfire/bin/setup:84-104` follows the same reset/prepare split, then starts the one
required development service only when it is absent. Fizzy's setup configures Git hooks before
installing gems (`fizzy/bin/setup:149-175`) and seeds only an empty non-CI database
(`fizzy/bin/setup:185-195`).

**Rules:**

- Put local bootstrap in `bin/setup`; make normal execution convergent.
- Reserve destructive work for an explicit `--reset`; do not hide it in the ordinary path.
- Use `rails db:prepare`, not a bespoke migration/create sequence.
- Finish by removing logs and temporary files, not by leaving a half-configured checkout.
- Start a dependent local service only if the application actually needs one.

> Divergence: Fizzy's setup deliberately has more platform management (mise, Brew/pacman, optional
> MySQL); Writebook's 26-line script is the preferred baseline. Add the extra machinery only when
> the supported development environments require it.

## CI is a readable, ordered release gate

Keep CI in `config/ci.rb`, in the order a developer would run it: setup, style, dependency/security
checks, tests, signoff. The commands are plain shell commands, not a second build system.

`fizzy/config/ci.rb:9-35`:

```ruby
CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Style: Ruby", "bin/rubocop -f simple"
  step "Gemfile: Drift check", "bin/bundle-drift check"
  step "Security: Gem audit", "bin/bundler-audit check --update"
  step "Security: Importmap audit", "bin/importmap audit"
  step "Security: Brakeman audit", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Security: Gitleaks audit", "bin/gitleaks-audit"
  step "Tests: Setup phases", "test/setup-phases-test"
end
```

Campfire uses the same shape, including an explicit seed test and failure signoff
(`once-campfire/config/ci.rb:3-22`). Fizzy's later `if success?` block runs `gh signoff`
(`fizzy/config/ci.rb:32-36`). It forces `PARALLEL_WORKERS=1` for its system-test command
because browser tests are not reliable in parallel (`fizzy/config/ci.rb:5-7, 28-29`).

**Rules:**

- Give each CI step a human-readable name and one command.
- Run the security checks that match your stack: Bundler audit, importmap audit, Brakeman, and
  secret scanning when available.
- Run system tests serially if their driver or shared state makes parallel runs flaky.
- Treat setup and seed data as tested product code, not developer folklore.
- Make a green run an explicit release/merge gate.

> Divergence: `config/ci.rb` is present in Fizzy and Campfire, not Writebook. It is a useful
> convention, not Rails-required infrastructure. Fizzy alone currently runs the Gemfile-drift and
> Gitleaks checks.

## Start with RuboCop Omakase

All three applications inherit the Rails-maintained baseline instead of maintaining a large local
cop configuration. Fizzy adds exactly two stylistic choices and excludes generated schema/migration
files.

`fizzy/.rubocop.yml:1-20`:

```yaml
# Omakase Ruby styling for Rails
inherit_gem: { rubocop-rails-omakase: rubocop.yml }

AllCops:
  Exclude:
    - 'db/migrate/**/*'
    - 'db/schema*.rb'

Style/NegatedIf:
  Enabled: true
Style/NegatedUnless:
  Enabled: true
```

**Rules:**

- Inherit `rubocop-rails-omakase`; add a local rule only for a genuine team decision.
- Exclude generated migration/schema output rather than forcing it into hand-written style.
- Keep styling enforcement in CI and make the local executable (`bin/rubocop`) the command people run.

## Ship a boring multi-stage container

The Dockerfiles are production images, not development environments. Build gems and precompiled
assets in a throw-away stage, then copy only what runs. Run the final image as an unprivileged user.

`fizzy/Dockerfile:30-54, 59-83`:

```dockerfile
FROM base AS build
COPY Gemfile Gemfile.lock vendor ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile
COPY . .
RUN bundle exec bootsnap precompile -j 1 app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

FROM base
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/thrust", "./bin/rails", "server"]
```

Writebook reaches the same shape in `Dockerfile:17-64`; Campfire does so in `Dockerfile:24-79`.

**Rules:**

- Separate build dependencies from the final runtime image.
- Precompile assets with `SECRET_KEY_BASE_DUMMY=1`; never bake a real secret into the image.
- Remove package-manager and Bundler caches in the build stage.
- Create and use a non-root `rails` user in the final stage.
- Let the image entrypoint prepare the application; use Thruster/Puma as the web process, not a
  process supervisor you wrote yourself.

## Deployment follows the product's operational boundary

Fizzy's self-hosted deployment is Kamal: one `config/deploy.yml` names the service, server, proxy,
secrets, persistent volume and image builder. Its persistent SQLite/Active Storage volume is explicit:

`fizzy/config/deploy.yml:17-35, 52-64`:

```yaml
proxy:
  ssl: true
  host: fizzy.example.com
env:
  secret:
    - SECRET_KEY_BASE
    - VAPID_PUBLIC_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true
volumes:
  - "fizzy_storage:/rails/storage"
asset_path: /rails/public/assets
builder:
  arch: amd64
```

**Rules:**

- Commit deploy configuration; keep its secrets outside Git.
- Declare durable storage and backup it. SQLite and local Active Storage are product data.
- Bridge fingerprinted assets across deploys so in-flight requests do not receive 404s.
- Keep deployment configuration close to the app and executable through `bin/` aliases.

> Divergence: Fizzy uses Kamal (`fizzy/Gemfile:13-22` and `config/deploy.yml`); Campfire and
> Writebook use an ONCE-style Docker/Procfile process layout (`once-campfire/Procfile:1-3`,
> `writebook/Procfile:1-3`). The shared rule is a small, self-hostable container; choose the
> deploy command that matches the product, not both.
