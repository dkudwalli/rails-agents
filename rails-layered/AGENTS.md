# Project Configuration

> **This is a template.** Copy it into your application as `AGENTS.md` or `CLAUDE.md` when you
> install the `rails-layered` plugin, then fill in the profile block below for your project.

## Application profile

```
Profile: Layered (the `rails-layered` plugin) — a deliberate divergence from the 37signals playbook
Reason: <one product constraint that justifies the extra layers>
Deliberate divergences:
  - PostgreSQL, where the playbook starts with SQLite
  - RSpec + FactoryBot, where the playbook uses Minitest + fixtures
  - Pundit policies, where the playbook uses scoped lookups plus model predicates
  - ViewComponent + Tailwind, where the playbook uses ERB partials, helpers, and plain CSS
  - `app/services`, `queries`, `forms`, `policies`, `presenters` — layers the playbook does not create
```

The rows above are this profile's divergences *from the playbook*. Add your own application's to the
same list — an existing app on SQLite, on Minitest, or with no `app/services` records that here, and
the corresponding row below stops applying to it. A recorded divergence is a decision, not debt, and
nothing in this pack requires changing a database or a test framework to adopt the layers.

Everything below describes **that** profile. It is not the 37signals default. If you want the
playbook conventions instead, install the `rails-37signals` plugin, whose `CLAUDE.md` template
carries its own profile block. Do not install both — they disagree on database, test framework,
authorization, CSS, and whether a service layer exists at all.

## Tech Stack

A row listed under **Deliberate divergences** above overrides its entry here. This is the default for
a new application, not a requirement of the plugin.

- **Ruby** 3.3, **Rails** 8.1, **PostgreSQL**
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS 4, ViewComponent
- **Testing:** RSpec, FactoryBot, Shoulda Matchers, Capybara
- **Auth:** `has_secure_password` (Rails 8 built-in), Pundit (authorization)
- **Background Jobs:** Solid Queue (database-backed, no Redis)
- **Caching:** Solid Cache | **WebSockets:** Solid Cable
- **Assets:** Propshaft + Import Maps (no Node.js)
- **Deployment:** Kamal 2 + Thruster

## Architecture

```
app/
  controllers/     # Thin. Delegates to services. Renders responses.
  models/          # Persistence: validations, associations, scopes, simple predicates.
  views/           # ERB markup only. No logic.
  services/        # Business logic. Orchestrates models, APIs, side effects.
  queries/         # Complex database queries. Returns relations or hashes.
  forms/           # Multi-model form objects.
  policies/        # Pundit authorization. Default deny.
  presenters/      # View formatting (SimpleDelegator).
  components/      # ViewComponents (reusable UI with tests).
  jobs/            # Background jobs (Solid Queue). Must be idempotent.
  mailers/         # Email delivery. Always HTML + text templates.
```

## Key Commands

```bash
# Tests
bundle exec rspec                              # Full suite
bundle exec rspec spec/path/to_spec.rb         # Specific file
bundle exec rspec spec/path/to_spec.rb:25      # Specific line

# Linting
bundle exec rubocop -a                         # Auto-fix Ruby
bundle exec rubocop -a app/models/             # Specific directory

# Security
bin/brakeman --no-pager                        # Static analysis
bundle exec bundler-audit check --update       # Gem vulnerabilities

# Database
bin/rails db:migrate                           # Run migrations
bin/rails db:migrate:status                    # Check status
bin/rails console                              # Interactive console
```

## Development Workflow

Follow **TDD: Red -> Green -> Refactor**:
1. **RED:** Write a failing test describing desired behavior
2. **GREEN:** Write minimal code to pass the test
3. **REFACTOR:** Improve code structure while keeping tests green

## Core Conventions

- **Skinny Everything:** Controllers orchestrate. Models persist. Services contain business logic. Views display.
- **Callbacks:** Only for data normalization (`before_validation`, `before_save`). Side effects (emails, jobs, APIs) belong in services.
- **Services:** `.call` class method, return Result objects, namespace by domain (`Entities::CreateService`).
- **No premature abstraction:** Don't extract until complexity demands it. Three similar lines > wrong abstraction.
- **Explicit > implicit:** Clear service calls over hidden callbacks. Named methods over metaprogramming.

The full statement of every convention lives in the plugin's `layered-conventions` skill — one
reference file per layer, each keeping the `paths:` frontmatter that scopes it. Invoke the skill, or
copy the references into `.claude/rules/` for deterministic path-scoped loading:

```bash
mkdir -p .claude/rules
cp ~/.claude/plugins/marketplaces/rails-engineer/rails-layered/skills/layered-conventions/references/*.md .claude/rules/
```

## Naming Conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Model | Singular PascalCase | `Entity`, `OrderItem` |
| Controller | Plural PascalCase | `EntitiesController` |
| Service | Namespaced + `Service` | `Entities::CreateService` |
| Query | Namespaced + `Query` | `Entities::SearchQuery` |
| Policy | Singular + `Policy` | `EntityPolicy` |
| Job | Descriptive + `Job` | `ProcessPaymentJob` |
| Presenter | Singular + `Presenter` | `EntityPresenter` |
| Form | Descriptive + `Form` | `EntityRegistrationForm` |
