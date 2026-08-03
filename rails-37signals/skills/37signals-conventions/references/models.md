---
paths:
  - "app/models/**/*.rb"
  - "test/models/**/*.rb"
---

# Model Conventions (37signals)

- Rich domain models: business logic lives here, not in a service layer. Model methods are the public
  API that controllers call directly
- A plain object is fine; a *layer* is not. `Signup` belongs in `app/models/signup.rb` next to `Card`.
  Value objects, parsers, and query objects live in `app/models/` too — "model" means "part of the
  domain", not "subclass of `ActiveRecord::Base`"
- **Concerns are namespaced under the model they extend**: `app/models/card/closeable.rb` defining
  `Card::Closeable`. Promote to `app/models/concerns/` only when a second model includes it
- The class body reads as a table of contents — a long model is a list of `include`s, not a wall of
  methods. Each concern is a vertical slice owning its own association, scopes, predicates, and verbs
- Concerns are adjectives (`Closeable`, `Assignable`); state records are nouns (`Closure`, `Goldness`)
- **State as records, not booleans:** `has_one :closure` rather than `closed: boolean`. You get who
  and when for free, scopes become joins, and the state gets a URL
- Verb methods are idempotent and transactional; use `where.missing(:association)` for negative
  state scopes
- `belongs_to` defaults via lambdas: `default: -> { Current.user }`, so controllers never assign ownership
- `touch: true` on child→parent associations for cache invalidation
- Order by a timestamp **and** `id` so ties are deterministic; ordering scopes are adverbs
  (`chronologically`)
- Preloading belongs in a named scope, not scattered `includes` calls
- No foreign key constraints; integrity comes from `dependent:` on associations plus unique indexes
- Prefer `delegated_type` over STI
- Callbacks: lambdas for one-liners, always with `if:`; `after_create_commit` when the work must see
  committed data. Side effects that a reader would not expect belong in an explicit method
- `ApplicationRecord` stays nearly empty
- `_later`/`_now` for async/sync method pairs

> Fizzy profile only: `account_id` on every model, and an account-aware `Current`. Campfire and
> Writebook have no account layer at all — do not add one without the multi-account requirement.

See [`03-models.md`](../../../docs/37signals-playbook/03-models.md) and
[`13-absences.md`](../../../docs/37signals-playbook/13-absences.md).
