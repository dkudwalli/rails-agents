---
name: legacy-migration
description: >-
  Orders the work of bringing an existing, inherited, or legacy Rails codebase toward 37signals conventions — which refactoring to do first, what unblocks what, and what to leave alone. Use when the user wants to modernize, migrate, or clean up a whole existing application, has inherited a messy codebase, mentions a legacy Rails app, or asks where to start. WHEN NOT: Executing a single known refactoring (use `refactoring-patterns`), or finding the problems in the first place (use `review-patterns`).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Legacy Migration

An ordering, not a catalogue. The refactorings themselves live elsewhere:

| Reference | Read it for |
|---|---|
| [`anti-patterns.md`](../review-patterns/references/anti-patterns.md) | Finding what this app actually has. Run the audit before sequencing anything |
| [`refactoring-patterns.md`](../refactoring-patterns/references/refactoring-patterns.md) | Before/after for phases 1 and 2 |
| [`migration-strategies.md`](../refactoring-patterns/references/migration-strategies.md) | Step-by-step for phases 4, 5, and 6 |

**A rewrite is not on the table.** Every phase below is a sequence of one-file changes with a green
test suite between each one. An app that cannot be shipped mid-migration has been sequenced wrong.

## Phase 0 — Decide what you are migrating toward

Nothing else starts until the target application's `CLAUDE.md` carries a filled-in
`## Application profile` block. A two-year-old codebase has none, and half the refactorings below
change meaning depending on it — an ONCE-compatible app keeps Redis and Resque, so phase 5 is not
work, it is a mistake. The template is in this pack's `CLAUDE.md`.

Then get the existing suite green and fast, whatever framework it is written in. Do **not** convert
it yet. It is the only thing standing between phases 1–5 and a silent regression.

**Stop here if** the suite is too thin to catch a regression. Backfilling tests against current
behaviour *is* the next phase, in the framework already in use.

## Phase 1 — The surface

God controller → CRUD resources. Serializers, GraphQL, and `as_json` overrides → jbuilder, if the app
has an API.

First because routes and controllers are what every later phase hangs off. State records need a
controller to be created and destroyed through; scoped lookups replace authorization inside a
controller action. Doing this after phase 2 means touching the same controllers twice.

**Stop here if** the controllers are already resourceful. Custom actions on an otherwise CRUD
controller are a phase-2 problem, not a phase-1 one.

## Phase 2 — The domain shape

In this order, and the order matters:

1. **Service objects → model methods.** The logic has to be findable before it can be reshaped.
2. **Callback chains → explicit calls.** Once the logic is in the model, the callbacks are what it
   was hiding behind.
3. **Booleans and timestamps → state records.** Needs the phase 1 controllers to hang off, and needs
   step 2 done or the callbacks fire against a column that no longer exists.
4. **Flat concerns → namespaced concerns.** Last. Moving `app/models/concerns/closeable.rb` to
   `app/models/card/closeable.rb` is cheap and pointless until the model has stopped moving. Promote
   to `concerns/` only where a second model genuinely includes it.

This is the phase that produces the actual 37signals shape. If the migration is only ever going to
get one phase of budget, make it this one.

**Stop here if** a service object has a stable boundary that is neither model nor controller. A
plain object in `app/models/` is a fine landing place; it is the `app/services/` *layer* that goes.

## Phase 3 — Authorization, then authentication

Pundit and CanCan → scoped lookups that 404, plus `can_<verb>_<noun>?` predicates on `User`.
Then Devise → a `Session` record and a signed cookie.

Both need phase 1: a scoped lookup replaces `authorize @record` inside a resourceful action.
Authorization first, because replacing authentication is the single riskiest change in this document
— it can lock every user out of a production application, so it goes behind a feature flag with both
paths live, and it goes when nothing else is in flight.

**Stop here if** the policy matrix has genuinely outgrown clear local code. The playbook's own
carve-out.

## Phase 4 — The frontend, strictly in this order

React/Vue/SPA → Turbo + Stimulus → build step → importmap → Tailwind/Sass → plain layered CSS →
ViewComponent/presenters → partials plus `*_tag` helpers.

The order is a hard dependency, not a preference: the build step cannot be removed while a SPA still
needs it, and Tailwind cannot be removed while the build step that compiles it is what the SPA
requires. Going in any other order means reinstating something you just deleted.

**Stop here if** a required browser dependency cannot be loaded through importmap, or a measured
design-system need demands CSS tooling.

## Phase 5 — Runtime

Sidekiq → the queue the profile selected. Redis → Solid Cache and Solid Cable.

Deferrable indefinitely. It is coupled to nothing above it, invisible to users, and touches
production infrastructure. Never run both stacks against the same work.

**Stop here if** the profile is ONCE-compatible. Redis and Resque are the target there, not the
thing being migrated away from.

## Phase 6 — The test suite

RSpec + FactoryBot → Minitest + fixtures.

Last, or never. Highest churn and lowest user-visible value of anything here, and doing it early
destroys the safety net that phases 1–5 depend on. A green RSpec suite is worth more than a
half-converted Minitest one. Convert file by file as tests are touched for other reasons, rather than
as a project.

**Stop here if** the suite is large and passing. This phase is the one most safely skipped forever.

## When to stop

- A phase whose anti-patterns the audit did not flag is a phase to skip. Do not migrate toward a
  pattern the app does not need.
- The profile's non-goals are legitimate stopping points, not incomplete work.
- Phases 1–3 are the migration. Phases 4–6 are optional in a way they are not.

## What has no worked example yet

`refactoring-patterns.md` covers service objects, state records, god controllers, callback chains,
and pulling a shared concern out of a fat model. `migration-strategies.md` covers RSpec, Sidekiq,
React, and Redis. The rest — Devise → custom auth, Pundit → scoped lookups, flat → *namespaced*
concerns, build step → importmap, ViewComponent → partials, serializers → jbuilder — have no
before/after in this pack. Their target state is documented in the `auth-setup`, `concern-patterns`,
`css-design`, and `api-patterns` skills; the path there is yours to work out.
