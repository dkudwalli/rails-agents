---
name: rich-models-model-patterns
description: >-
  Builds rich domain models with business logic, concerns, and proper
  associations following the fat-models-over-service-objects philosophy.
  Use when creating models, adding validations, scopes, callbacks, business
  logic methods, or associations.
  Applies only in a rich-models profile app.
  WHEN NOT: A layered profile app — use layered-model-patterns. Controller/routing work (use crud-patterns), concern extraction
  (use concern-patterns), state record design (use state-records).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Model Patterns (37signals)

Rich domain models over a service layer. Business logic lives in models, not in a parallel directory
of `*Service` classes.

**"Model" means "part of the domain", not "subclass of `ActiveRecord::Base`."** Value objects,
parsers, query objects, and generators live in `app/models/` next to the records — a `Struct`, a
`Search::Query`, an `HtmlScrubber`. A plain object is fine; a *layer* is not. If you are creating a
directory to hold a *category* of object, you have built a layer.

> Fizzy profile only: UUID primary keys and `account_id`/`Current.account` in the reference examples.
> Check the `## Rails Engineer Profile` block in `AGENTS.md` first.

## Rich model vs service object

```ruby
# BAD -- service object
class CloseCardService
  def initialize(card, user)
    @card = card
    @user = user
  end

  def call
    ActiveRecord::Base.transaction do
      @card.create_closure!(user: @user)
      @card.track_event("card_closed", user: @user)
    end
  end
end

# GOOD -- rich model
class Card < ApplicationRecord
  include Closeable

  def close(user: Current.user)
    create_closure!(user: user)
    track_event "card_closed", user: user
    notify_recipients_later
  end
end

# Controller simply calls:
@card.close
```

## References

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`structure.md`](references/structure.md) | Ordering within a model, generator commands, `delegated_type` over STI |
| [`associations-and-scopes.md`](references/associations-and-scopes.md) | `belongs_to` defaults, polymorphic, counter caches, ordering and `where.missing` scopes |
| [`validations-and-callbacks.md`](references/validations-and-callbacks.md) | Validation recipes, when a validation is not an invariant, callback discipline, string enums |
| [`business-logic.md`](references/business-logic.md) | Action, predicate, and computed methods; the `_later`/`_now` pair; `Current` |
| [`model-examples.md`](references/model-examples.md) | Complete worked models — concerns, state records, join tables, polymorphic, POROs |

## Boundaries

- **Always:** Put business logic in models, use namespaced concerns for organization, use bang methods
  (`create!`, `update!`), leverage associations and scopes, use `Current` for request context, default
  values via lambdas, tie-break orderings on `id`
- **Ask first:** Before adding a plain object — it is allowed, but it belongs in `app/models/` with a
  domain name, never in a category directory. Before adding a callback with a side effect. Before
  using inheritance (prefer composition via concerns)
- **Profile override:** if the app's `AGENTS.md` records `app/services` or another category
  directory under **Deliberate divergences**, that row wins over the Never rule below — write in
  the idiom the app already runs. Removing it is `rich-models-legacy-migration`'s call, not a precondition for
  the task at hand.
- **Never:** Create anemic models (data without behavior), create an `app/services/` directory, put
  business logic in controllers, rely on ambient `Current` inside a job, create models without tests

Rules live in `37signals-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.

See [`03-models.md`](../../docs/37signals-playbook/03-models.md).
