---
name: extraction-timing
description: >-
  Guides decisions about when and how to extract code into services, queries,
  concerns, form objects, or other patterns. Use when deciding whether to
  extract code, choosing between patterns (service vs concern vs query),
  evaluating if a base class or abstraction is needed, or when user mentions
  refactoring, extraction, code organization, or "where should this go."
  WHEN NOT: Implementing a specific pattern already decided on (use specialist
  agents like service-agent, query-agent, or model-agent), writing tests
  (use rspec-agent), architecture-level design (use rails-architecture), or
  planning the order of work across a whole legacy codebase (use
  legacy-migration).
user-invocable: true
---

You are an expert in Rails code organization and extraction decisions. Help decide **when** to extract, **what pattern** to use, and **when to keep it simple**.

## Core Philosophy: Skinny Everything

The 2025 Rails consensus has evolved beyond "Fat Models" to **Skinny Everything**:
- **Controllers**: orchestrate (delegate to services, render responses)
- **Models**: persist (validations, associations, scopes, simple predicates)
- **Services**: contain business logic (multi-step operations, external calls, orchestration)
- **Views**: display markup with zero logic

## Extraction Thresholds

This table is the single source of truth for extraction numbers in this pack. Other skills, rules, and
agents point here rather than restating a threshold -- if you find a competing number elsewhere, this table
wins and the other file is a bug.

| Signal | Threshold | Action |
|--------|-----------|--------|
| Controller action | > 10 lines of *business logic* (strong params, `render`, `redirect_to` don't count) | Extract to service object |
| Model size | 150 lines | Review: business logic has crept back in. Extract to services and query objects |
| Model size | 300 lines | God object territory -- line count alone can't decide. See `references/god-objects.md` |
| Model complexity | `flog -s` > 100 | Decompose |
| Model churn | > 30 changes/year | Review for extraction |
| Callback score | <= 2/5 | Extract to service (see Callbacks vs Explicit Calls below) |
| Query | Joins 2+ tables, OR has conditional clauses, OR reused in 2+ places | Extract to query object |
| Form touches multiple models or has custom validation | -- | Extract to form object |
| Display formatting logic in model | -- | Extract to presenter |
| UI element reused across 2+ views | -- | Extract to ViewComponent |
| Shared behavior across 2+ models (narrow, simple) | -- | Extract to concern |
| Concern | ~30 lines | Extract to a delegate object or separate model |
| Identical structure repeated | 5+ concrete implementations | Extract base class |
| Same code in 3+ places | -- | Extract to concern or service |
| One-off operation | -- | **Don't extract. Inline is fine.** |

**Why model size has two tiers.** 150 is the actionable line: in this profile services carry the business
logic, so a model past 150 lines is the signal that logic leaked back into the model. 300 is a handoff, not
a louder warning -- past it the question stops being "extract this method" and becomes "is this a god
object," which needs churn and complexity, not line count.

## Decision Tree: "Where Should This Code Go?"

```
Is it a database query?
  ├── Simple (one table, one condition) → Model scope
  └── Complex (joins, conditionals, reused) → Query object

Is it business logic?
  ├── Simple CRUD on one model → Controller inline (or model method)
  ├── Multi-step operation → Service object
  ├── Involves external API → Service object
  └── Spans multiple models → Service object with transaction

Is it shared behavior?
  ├── Property of the model (soft-delete, slugs, search) → Concern
  └── Operation on the model (checkout, import, sync) → Service object

Is it display logic?
  ├── Formatting one model's data → Presenter (SimpleDelegator)
  ├── Reusable UI element → ViewComponent
  └── Simple helper method → Keep in helper (use sparingly)

Is it validation?
  ├── Single model, standard rules → Model validation
  ├── Multi-model form → Form object
  └── Business rule (not data integrity) → Service validation
```

## Settled Debates

### Concerns vs Service Objects

| | Concerns | Service Objects |
|--|---------|----------------|
| **Use for** | Simple shared model properties | Multi-step business operations |
| **Examples** | `SoftDeletable`, `Searchable`, `Sluggable` | `CreateOrder`, `ProcessRefund`, `ImportCsv` |
| **Max size** | ~30 lines | No hard limit (but SRP applies) |
| **Test via** | Including model's specs | Isolated unit specs |

**Rule:** If the behavior is a *property* of the model, use a concern. If it's an *operation* on the model, use a service.

### STI vs Polymorphic Associations

| | STI | Polymorphic |
|--|-----|------------|
| **Use when** | Subclasses share >80% of columns | Types have unique attributes |
| **Table** | One shared table with `type` column | Separate tables per type |
| **Avoid when** | >20% columns are NULL for some subtypes | Types are fundamentally similar |

### Callbacks vs Explicit Calls

**Rule:** Callbacks maintain the record's own data. Everything else is explicit.

Score each callback rather than judging it by macro name -- `after_commit` is not automatically wrong and
`before_save` is not automatically fine. What matters is whether the callback stays inside the record.

| Score | Type | What it does | Example | Verdict |
|-------|------|--------------|---------|---------|
| 5 | Transformer | Computes or defaults this record's own attributes | `before_validation :compute_slug` | Keep |
| 4 | Maintainer | Keeps derived data consistent | `counter_cache: true`, `touch: true` | Keep |
| 3 | Timestamp | Stamps a state change onto this record | `before_save :set_published_at` | Review -- often a sign the state change belongs in a service |
| 2 | Background trigger | Enqueues async work | `after_commit :enqueue_sync` | Extract |
| 1 | Operation | Runs a business process step: emails, external APIs, creating other models' records | `after_create :send_welcome_email` | Extract immediately |

**Cut line: extract at <= 2. Review at 3. Keep 4 and 5.**

Signs a callback is really a 1 even if it looks smaller: it has a condition (`unless: :admin?`), it
collaborates with a non-model object (mailer, API client, job), or it talks to a remote peer.

Prefer Rails 7.1+ `normalizes` over writing a score-4 normalizer callback by hand:

```ruby
normalizes :email, with: -> (email) { email.strip.downcase }
```

**SDD constitution mapping.** The constitution (§III) states callbacks are restricted to data normalization.
In rubric terms: **score >= 4 satisfies §III, 3 is flagged for review, <= 2 violates it.**

## Anti-Pattern Checklist

Before extracting, verify you're not creating:
- [ ] A service that wraps a single `model.update!` call (Service Graveyard)
- [ ] A base class for only 2 services (Premature Abstraction)
- [ ] A concern with multiple responsibilities (Kitchen Sink Concern)
- [ ] A helper that should be a presenter or component
- [ ] An abstraction for a hypothetical future need (YAGNI violation)

Read the `behavioral-guidelines` skill § Simplicity First and apply it on top of this checklist. The
checklist catches bad extractions; those rules catch the case where no extraction was warranted -- nothing
speculative, no abstraction for single-use code, no configurability nobody requested. A threshold firing is
permission to extract, not an obligation.

## Related

- **the `rails-architecture` skill** -- which layer owns a responsibility, allowed call
  directions, and the agent that builds each artifact. Use it for "what should exist"; use this skill for
  "is it time to extract."
- **the `specification-test` skill** -- decides layer placement from the shape of the test a
  piece of code needs. Reach for it when a threshold here fires but the destination layer is unclear.
- **`references/god-objects.md`** -- churn x complexity analysis for models past 300 lines.
- **the `layered-legacy-migration` skill** -- the order to take these extractions in across a whole existing
  application, and which ones to skip. Reach for it when the question is "where do I start" rather
  than "is this one ready."
- **the `behavioral-guidelines` skill** § Simplicity First -- the prior question: does this code need to
  exist at all. Read it before any extraction decision here.
