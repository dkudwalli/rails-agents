# 20 — Performance & operability

Make the normal path observable and bounded before reaching for infrastructure. The apps' tools are
query scopes, preload groups, framework caching, request-tagged logs, health endpoints, and small
operational records — not a performance abstraction layer.

---

## Give common query shapes a name

Fizzy puts stable ordering and display preload plans on the model:

`fizzy/app/models/card.rb:22-26`:

```ruby
scope :reverse_chronologically, -> { order created_at:     :desc, id: :desc }
scope :chronologically,         -> { order created_at:     :asc,  id: :asc  }
scope :latest,                  -> { order last_active_at: :desc, id: :desc }
scope :with_users,              -> { preload(creator: [ :avatar_attachment, :account ], assignees: [ :avatar_attachment, :account ]) }
scope :preloaded,               -> { with_users.preload(:column, :tags, :steps, :closure, :goldness, :activity_spike, :image_attachment, reactions: :reacter, board: [ :entropy, :columns ], not_now: [ :user ]).with_rich_text_description_and_embeds }
```

**Rules:**

- Name a repeated ordering or preload graph as a scope close to its associations.
- Preload for a real rendering/query boundary; do not add speculative preload-all scopes.
- Keep timestamp ordering deterministic with `id` as the tie breaker.
- Use `find_each` or a resumable job for unbounded maintenance; do not materialize a whole table in a
  web request.

## Use Rails' cache layers before inventing one

Fizzy defines a resource-level ETag and invalidates it when the import map changes
(`fizzy/app/controllers/application_controller.rb:1-12`). Its production configuration chooses Solid
Cache; Campfire and Writebook choose Redis (`fizzy/config/environments/production.rb:98-103`,
`once-campfire/config/environments/production.rb:70-75`,
`writebook/config/environments/production.rb:43-49`).

**Rules:**

- Start with fragment/collection caching in views and HTTP freshness in controllers; see
  [`05-views-helpers.md`](05-views-helpers.md).
- Keep cache store choice at the environment boundary.
- Version cache/ETag inputs when a shared asset or rendering contract changes.
- Do not hide cache keys behind a home-grown wrapper until the key is genuinely reused and complex.

## Production should be observable without an agent

Each application logs to stdout with request-id tagging (`fizzy/config/environments/production.rb:85-96`,
`once-campfire/config/environments/production.rb:51-65`,
`writebook/config/environments/production.rb:30-41`). Fizzy adds account and identity only when Rails
reports an error (`fizzy/config/initializers/error_context.rb:1-7`).

**Rules:**

- Emit logs to stdout, tag them with request id, and make log level deploy-configurable.
- Add tenant/user context only to error reporting, not as a reason to log personal data on every line.
- Filter secrets globally before they reach logs (`fizzy/config/initializers/filter_parameter_logging.rb:1-8`).
- Keep health checks cheap and separate from application traffic; all three expose Rails' `/up` route
  (`fizzy/config/routes.rb:252-254`, `once-campfire/config/routes.rb:94-97`,
  `writebook/config/routes.rb:76-78`).

## Bound expensive work and preserve its recovery path

Webhook delivery limits timeout and response size rather than trusting a remote endpoint
([`19-integrations-webhooks.md`](19-integrations-webhooks.md)). Fizzy's storage totals use a snapshot
plus pending deltas (`fizzy/app/models/storage/total.rb:1-11`) and attachment tracking records an
attach/detach delta only after commit (`fizzy/app/models/storage/attachment_tracking.rb:1-51`).

**Rules:**

- Put time, byte, batch, and retention limits next to the operation they constrain.
- Persist enough state to resume, reconcile, or inspect long-running work.
- Use database-level counters/locks for contested mutable totals; see [`09-data-search.md`](09-data-search.md).
- Add monitoring infrastructure only when stdout logs, error reports, job visibility, and a health
  endpoint no longer answer the operational question.

## Related

- [`08-jobs-async.md`](08-jobs-async.md) — queues, recurring jobs, and batch work.
- [`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md) — container/deploy production baseline.
- [`14-divergences.md`](14-divergences.md) — Solid versus Redis operational choices.
