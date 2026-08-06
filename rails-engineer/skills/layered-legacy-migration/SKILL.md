---
name: layered-legacy-migration
description: >-
  Orders the work of bringing an existing Rails codebase onto the layered profile — which extraction to do first, what unblocks what, and what to leave alone. Use when the user wants to modernize, migrate, or adopt layered architecture across a whole existing application, has inherited a Rails codebase, or asks where to start. WHEN NOT: Executing a single known extraction (use `extraction-timing`, then the matching `<layer>-patterns` skill), deciding which layer one file belongs to (use `specification-test`), or finding the problems in the first place (use `code-review`).
user-invocable: true
compatibility: Ruby 3.1+, Rails 7.0+
---

# Legacy Migration

An ordering, not a catalogue. The work itself lives elsewhere:

| Reference | Read it for |
|---|---|
| [`code-review`](../code-review/SKILL.md) | The audit. Run it before sequencing anything |
| [`anti-patterns.md`](../layered-conventions/references/anti-patterns.md) | Named anti-patterns: God Model, Service Graveyard, Callback Spaghetti |
| [`extraction-timing`](../extraction-timing/SKILL.md) | Every threshold and the callback rubric. The pack's single source of truth for extraction numbers |
| [`god-objects.md`](../extraction-timing/references/god-objects.md) | Churn x complexity analysis, and the two leave-alone rules |
| [`specification-test`](../specification-test/SKILL.md) | Deciding what moves out of a file, one file at a time |
| [`patterns.md`](../tdd-refactoring/references/patterns.md) | Before and after for the mechanical extractions |
| [`current.md`](../authentication-flow/references/current.md) | The `Current.user`-in-models rule for phase 3 |
| [`mutation-testing`](../mutation-testing/SKILL.md) § Prepare a Legacy Project | Seeding a mutant baseline on an app with no ignore list |

Do not restate a threshold, a rubric, or a before/after here. Every number in this pack lives in
`extraction-timing`, and a competing copy is a bug.

**This skill's `compatibility:` is deliberately below the rest of the pack.** Everything else here
targets Ruby 3.3+ / Rails 8.0+. A brownfield skill runs on old applications by definition — asserting
Rails 8 would exclude every codebase it exists for. Upgrading Rails is not one of the phases below;
it is its own project, and the phases work on any version from 7.0.

**A rewrite is not on the table.** Every phase below is a sequence of one-file changes with a green
test suite between each one. An app that cannot be shipped mid-migration has been sequenced wrong.

## Phase 0 — Target profile, green suite, audit

Nothing else starts until three things are true.

**One: the target application carries a filled-in profile block.** Copy the `## Application profile`
block from this pack's `AGENTS.md` into the target app's `AGENTS.md` or `CLAUDE.md`, and fill in the
literal `Reason: <one product constraint that justifies the extra layers>` placeholder. The layered
profile is a deliberate divergence from vanilla Rails — five extra directories that a plain Rails app
does not have. That cost needs a reason written down before anyone starts paying it.

**Stop here if** the reason cannot be named. An app with no constraint driving the extra layers
belongs on the `rails-37signals` profile, and every phase below is cost with no return.

**Two: the existing suite is green and fast, in whatever framework it is already written in. Do not
convert it.** The profile names RSpec + FactoryBot, and `layered-conventions` gates its rules on that
— but that gate governs the code written *during* this migration, not the suite already in the
repository. A Minitest suite is a perfectly good safety net, and it is the only thing standing
between the phases below and a silent regression. Conversion is a phase 6 question, and the answer is
usually no.

**Stop here if** the suite is too thin to catch a regression. Backfilling tests against current
behaviour *is* the next phase, in the framework already in use.

**Three: the audit has run and produced a candidate list.** Sequencing before the audit is guessing.

## Phase 1 — Controllers, one resource at a time

Fat action → service object. Work one controller at a time, shipping each.

First because controllers are the entry point, and every phase below depends on knowing where the
business logic actually lives. A model cannot be assessed while half its behaviour is still inlined
in a controller action.

**Stop here if** the controllers are already thin. A controller that finds a record, calls one
object, and renders is done — custom actions on it are a phase 3 problem.

## Phase 2 — Authorization, before models

This phase forks three ways on what the app already has. Establish which case you are in first,
because two of the three are not migration work.

1. **Access rules scattered through models and controllers** → extract to Pundit policies, default
   deny. This is the case the phase is positioned here for. Scattered access rules are a leading
   cause of fat models, so pulling them out shrinks the model before phase 3 tries to decompose it,
   and it is the one phase that pays off in security on day one.
2. **A coherent authorization layer in another gem** → leave it. The profile names Pundit; a working
   authorization layer is never worth a rewrite. Note the divergence in the profile block and move on.
3. **No authorization layer at all** → this is not migration work. There is nothing to extract, so
   introducing Pundit across every controller is net-new feature work, and it does not belong in the
   middle of a refactoring sequence where it will be reviewed as cleanup. Schedule it separately, and
   go straight to phase 3.

**Stop here if** you are in case 2 or 3.

## Phase 3 — The domain shape

In this order, and the order matters:

1. **Callbacks scoring <= 2/5 → services.** First, because callbacks are what makes every later
   change to the model unpredictable — you cannot reason about an extraction while an `after_create`
   is firing a mailer behind it. The rubric is in `extraction-timing`; score each callback rather
   than judging it by macro name.
2. **Query logic → query objects.** Second, because it is mechanical, it shrinks the model
   measurably, and it carries the least behaviour risk of anything in this phase.
3. **`Current.user`, mailers, HTTP clients, and job enqueues inside models → push out.** These are
   layer violations rather than size problems, and each one removed makes the model testable in
   isolation.
4. **God-object decomposition, last.** Only for models still over threshold after 1–3. Most are not:
   steps 1–3 routinely take a 400-line model under the line without anyone deciding to decompose it.

This phase is where the layered shape actually appears. If the migration gets one phase of budget,
make it this one.

**Stop here if** `god-objects.md`'s leave-alone rules apply. High churn with low complexity means
active development — leave it. High complexity with low churn means settled — leave it. Only the
intersection of both is a candidate, and line count alone never is.

## Phase 4 — Presentation, strictly in this order

Presenters → ViewComponents → Turbo and Stimulus → Tailwind.

The order is cheapest-first and least-template-churn-first. Presenters move display logic out of
models without touching a single template. ViewComponents change the templates but not the
behaviour. Hotwire changes the behaviour. Doing these in any other order means rewriting the same
templates two and three times.

**Stop here if** the views work and nobody is touching them. This phase has the highest churn and the
lowest user-visible value of anything above it.

## Phase 5 — Forms

Multi-model and wizard forms → form objects.

After phases 1–3 because a form object's job is to validate and then hand off to the service layer —
built before that layer exists, it becomes a second place for business logic to hide.

**Stop here if** the forms map to a single model. `accepts_nested_attributes_for` on one parent is
not a form object candidate.

## Phase 6 — Runtime and the test suite

Both optional, both deferrable indefinitely.

**Runtime.** Solid Queue and PostgreSQL, if not already there. Coupled to nothing above it, invisible
to users, and it touches production infrastructure. Never run two job backends against the same work.
The layers do not depend on the adapter — an app on SQLite or MySQL records that as a divergence and
skips this half of the phase outright. Swap a working production database only for a capacity or
feature requirement you can name.

**The test suite.** The profile names RSpec + FactoryBot, and this is where that gets decided — not
in phase 0. The answer is usually a dual suite: write new specs in RSpec, leave the existing suite in
whatever framework it is in, run both in CI. Rails supports this indefinitely and it costs one extra
CI step. Converting an existing suite is the highest-churn, lowest-value work in this document, and
doing it early destroys the safety net phases 1–5 depend on.

**Stop here if** the existing suite is large and green. A dual suite is cheaper than a conversion,
permanently — this is the phase most safely skipped forever.

## When to stop

- A phase whose anti-patterns the audit did not flag is a phase to skip. Do not migrate toward a
  pattern the app does not need.
- Phases 0–3 are the migration. Phases 4–6 are optional in a way they are not.
- Every phase has a stopping point above, and reaching one is a result, not an unfinished job.

## What has no worked example yet

This pack has no equivalent of the 37signals pack's `migration-strategies.md` — there is no
step-by-step guide here for the operational half of a migration: sequencing a data backfill behind a
deploy, running two implementations side by side behind a flag, or cutting over a job backend without
double-processing. `patterns.md` covers the in-process refactorings, and the `<layer>-patterns`
skills document each target state, but the path from a running production app to that state is yours
to work out. Phase 6's runtime work is the one most exposed by this gap.
