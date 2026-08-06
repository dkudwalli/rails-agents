# 37signals Rails Configuration

> **This is a template.** Copy it into your application as `CLAUDE.md` or `AGENTS.md` when you
> install the `rails-37signals` plugin, then fill in the profile block below. Do not also install
> `rails-layered` — the two profiles disagree on database, test framework, authorization, CSS, and
> whether a service layer exists at all.

Derived from the vendored [37signals Rails Playbook](docs/37signals-playbook/README.md) —
rules extracted from `fizzy`, `once-campfire`, and `writebook` with a citation into real code behind
each one, observed 2026-08-01.

## Application profile

Fill this in before writing code. The three source applications disagree with each other, and the
playbook forbids averaging them into a hybrid stack
([`21-new-app-decisions.md`](docs/37signals-playbook/21-new-app-decisions.md)).

```markdown
Profile: Fizzy / ONCE-compatible
Reason: <one product constraint>
Deliberate divergences:
  - <each row that differs from the profile, and why it stays>
```

| | ONCE-compatible | Fizzy |
|---|---|---|
| Product boundary | One self-hosted account | Multiple accounts, or a credible path to them |
| IDs | Integer | UUIDv7, base36 representation |
| Primary database | SQLite | SQLite or MySQL/Trilogy |
| Jobs | Resque + resque-pool | Solid Queue |
| Cache / Cable | Redis | Solid Cache / Solid Cable |
| Deployment | Docker + Procfile | Kamal + Docker, persisted volume |

Solid Queue/Cache/Cable are **one** runtime decision; Redis/Resque/resque-pool are **one** other. Do
not run both for the same work. For a fresh self-hosted product with no ONCE compatibility
requirement: take Fizzy's Solid runtime, but keep SQLite and integer ids until a real multi-account
or identifier requirement changes them.

### Installing onto an existing application

Fill the divergence list **first**, from what the app already runs, before any skill in this pack is
asked for code. The rows above describe a target state, not a verdict on your stack, and a divergence
recorded here is a decision rather than debt. A brownfield list usually looks like:

```markdown
Profile: Fizzy
Reason: Multiple accounts already in production
Deliberate divergences:
  - PostgreSQL, not SQLite — it is in production and migrating it is not a project we are taking on
  - RSpec + FactoryBot — suite is large and green; see legacy-migration phase 6 ("last, or never")
  - Devise — auth replacement is the riskiest change in the pack and is not scheduled
```

Nothing here changes an app's database: `legacy-migration` has no database phase, and the audit in
`review-patterns` flags no adapter. Everything else the pack would reshape — test framework, queue,
authentication, frontend — is sequenced in `legacy-migration` behind an explicit **Stop here if**,
and every phase is skippable.

## Tech Stack

A row listed under **Deliberate divergences** above overrides its entry here. This is the default
for a new application, not a requirement of the plugin.

- **Ruby** 3.4, **Rails** 8.1+
- **Database:** SQLite by default; a database server only for a demonstrated product need
- **Frontend:** Hotwire (Turbo + Stimulus), Importmap + Propshaft — no Node.js, no build step
- **CSS:** plain CSS, one file per component — no Tailwind, Sass, or PostCSS
- **Testing:** Minitest + fixtures — not RSpec, not FactoryBot
- **Auth:** hand-rolled `Session` record + signed cookie; magic links and passkeys as needed — no Devise, no Pundit
- **Search:** in-database full-text search — no Elasticsearch, no search gem
- **Style:** `rubocop-rails-omakase` baseline
- **Deployment:** per the profile above

> **Edge Rails warning.** All three source applications pin Rails to git, not a release.
> `params.expect`, `ActiveSupport::ContinuousIntegration`, `broadcasts_refreshes` with morphing,
> resource-level `etag` blocks, and UUIDv7 primary keys may not exist or may behave differently on
> your Rails version. Verify before copying.

## Architecture

```
app/
  controllers/     # Thin. Find, call one model method, respond.
  models/          # Rich. The domain lives here — including POROs, parsers, and value objects.
  models/<model>/  # Namespaced concerns beside the model they extend.
  views/           # Plain ERB. Small partials. jbuilder for JSON.
  helpers/         # Build tags, not prose.
  javascript/      # Stimulus controllers, one behaviour each.
  jobs/            # Shallow. `_later` enqueues, `_now` performs, logic stays in the model.
  mailers/         # View-backed delivery objects.
  channels/        # Action Cable, only where a page refresh cannot express it.
  assets/stylesheets/  # One plain CSS file per component.
```

Standard Rails directories only. **Do not create a category until the code has earned it**
([`13-absences.md`](docs/37signals-playbook/13-absences.md)):

| Do not add by default | Use first | Add it only when |
|---|---|---|
| RSpec / FactoryBot / shoulda | Minitest, fixtures, Rails assertions | Rails' test support cannot express a real requirement |
| `app/services`, command/query/form layers | model method or a small namespaced model concern | behaviour has a stable boundary that is neither model nor controller |
| presenters / ViewComponent | ERB partial and helper | a component has a real independent lifecycle or public API |
| Tailwind / Sass / PostCSS | plain layered CSS, custom properties, native nesting | browser support or a measured design-system need demands tooling |
| npm, Webpack, esbuild, Vite | importmap plus browser modules | a required browser dependency cannot be loaded that way |
| Devise / Pundit / CanCan | authentication and authorization concerns plus scoped model lookups | the app's identity or policy matrix has outgrown clear local code |
| Sidekiq | the queue your profile selected | that queue cannot meet a measured operational need |
| Elasticsearch / OpenSearch | database search | database-backed search cannot satisfy the query or scale requirement |

A plain object is fine; a *layer* is not. `Signup` lives in `app/models/signup.rb` next to `Card`,
not as `SignupService` in a `services/` folder. If you are creating a directory to hold a *category*
of object, you have built a layer.

## Core Philosophy

- **Find the nearest existing example and copy its shape.** Before writing a new pattern, look for
  similar code elsewhere in the app. Nearly everything you need already exists somewhere. This is the
  single most load-bearing instruction here.
- **Vanilla Rails:** thin controllers invoking a rich domain model, with nothing in between.
- **Conceptual compression:** one name per concept, and the concept goes in the model. The
  interesting logic is `@card.close`; everything else in the controller is HTTP.
- **Everything is CRUD:** name state changes and relationships as nouns, then expose them as
  resources (`Closure`, `Publication`, `Watch`). When you want a verb endpoint, name the noun the
  verb creates or destroys.
- **State as records:** a boolean or timestamp becomes a `has_one` record when it needs a who, a
  when, or a URL.
- **Concerns for organization:** split a growing model into namespaced concerns beside it
  (`app/models/card/closeable.rb`); promote to `app/models/concerns/` only when a second model
  includes it.
- **Authorization is scoping:** a record the current user cannot reach is not found, and `find`
  raises → 404. Privilege checks beyond visibility are `can_<verb>_<noun>?` predicates on `User`.
- **Shallow jobs:** `_later` enqueues, `_now` performs; serialize context across the queue boundary
  rather than relying on ambient `Current`.
- **Plain Ruby objects are Rails too:** value objects, parsers, and query objects live in
  `app/models/`. "Model" means "part of the domain", not "subclass of `ActiveRecord::Base`".
- **Prefer the option that adds no new process, no new service, and no new build step.**
- **Prefer the framework's answer over a gem, and the newest framework answer over the one you
  learned first.**

## Key Commands

```bash
bin/setup                                    # Rerunnable. Destructive work behind --reset.
bin/dev                                      # Start dev server
bin/rails test                               # Full test suite
bin/rails test test/models/card_test.rb      # Specific file
bin/rails test test/models/card_test.rb:14   # Specific line
bin/rails test:system                        # System tests (run serially)
bin/ci                                       # Full CI via config/ci.rb
bundle exec rubocop -a                       # Auto-fix Ruby style
bin/rails db:migrate                         # Run migrations
bin/rails db:fixtures:load                   # Load fixture data
bin/rails db:prepare                         # Create/migrate as needed
```

## Development Workflow

1. Write a failing Minitest test, reaching for an existing fixture before creating a record
2. Implement the minimal code to make it pass
3. Refactor while tests stay green

## Naming Conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Model | Singular PascalCase | `Card`, `Board` |
| Namespaced concern | Adjective, under the model | `Card::Closeable`, `Card::Searchable` |
| Shared concern | Adjective, in `concerns/` | `Assignable` (2+ includers) |
| State record | Noun describing the state | `Closure`, `Publication`, `Goldness` |
| Controller | Plural, nested by resource | `Cards::ClosuresController` |
| Controller concern | `<Parent>Scoped` | `CardScoped`, `BoardScoped` |
| Async pair | `_later` / `_now` | `deliver_later` / `deliver_now` |
| Job | Namespaced under its model | `Event::RelayJob` |
| Ordering scope | Adverb | `chronologically`, `alphabetically` |
| Predicate | `can_<verb>_<noun>?` | `can_administer_card?` |
| Helper | `*_tag` returns an element | `card_tag`, `avatar_tag` |
| Test | `ModelTest` / `ControllerTest` | `CardTest`, `Cards::ClosuresControllerTest` |

## Style Guide

- **Expanded conditionals over guard clauses.** This is the single biggest stylistic difference from
  mainstream Rails — the source applications average roughly one guard clause per 1,000 lines of
  `app/`. Early return only at the start of a method, when it genuinely improves flow.
- `if identity = Identity.find_by(...)` — assignment inside the condition is deliberate and
  permitted by omakase.
- Method ordering: class methods → public instance (`initialize` first) → private. Order each
  section by invocation.
- **Indent the body below `private`, with no blank line under the keyword.** This requires
  `rubocop-rails-omakase`; stock RuboCop or Standard will fight the entire codebase.
- Bang methods (`!`) only where a non-bang counterpart exists — never merely to mark mutation.
- Let model method names describe domain transitions. Do not translate generic controller verbs into
  hidden business logic.
- `belongs_to :creator, default: -> { Current.user }` when the current context is truly the domain
  default.
- Order by a timestamp **and** `id` so ties are deterministic.

## Reference

The full playbook is vendored at [`docs/37signals-playbook/`](../docs/37signals-playbook/). Start
with [`PLAYBOOK.md`](docs/37signals-playbook/PLAYBOOK.md) for the condensed ruleset, and
[`15-review-checklist.md`](docs/37signals-playbook/15-review-checklist.md) for a review pass.
