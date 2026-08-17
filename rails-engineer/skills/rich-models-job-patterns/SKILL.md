---
name: rich-models-job-patterns
description: >-
  Implements shallow background jobs with _later/_now conventions using Solid
  Queue. Use when adding background processing, async operations, scheduled
  tasks, or when user mentions jobs, queues, workers, or background processing.
  Applies only in a rich-models profile app.
  WHEN NOT: A layered profile app — use layered-job-patterns. Business logic implementation (use rails-models), controller
  work (use crud-patterns), or mailer delivery (use rich-models-mailer-patterns).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+, Solid Queue
---

# Job Patterns (37signals)

Jobs orchestrate. Models do the work. Background jobs are thin wrappers around model methods.

> Profile decision: the queue backend is **Solid Queue** (Fizzy, database-backed, no Redis) or
> **Resque + resque-pool** (ONCE-compatible apps, Redis-backed). Solid Queue, Solid Cache, and Solid
> Cable are one runtime decision; Redis, Resque, and resque-pool are one other. Never run both for
> the same work. Sidekiq is not used in either profile. The references assume Solid Queue — check the
> `## Rails Engineer Profile` block in `AGENTS.md`.

## The non-negotiables

- **`perform` takes records, not ids.** Active Job serializes them via GlobalID
- **Enqueue from `after_*_commit`, never `after_save`** — a worker can only see committed rows
- **The `_later` method lives on the model**, usually private, and is the *only* place the job class
  is named. Nothing else in the app should reference `NotifyRecipientsJob`
- **Namespace jobs under the model that owns them**: `Event::RelayJob`, `Card::CleanupJob`
- **`ApplicationJob` stays a stub.** Declare `retry_on`/`discard_on` per job, because whether a
  vanished record is a bug depends on the job
- **Serialize the context the job needs.** Ambient `Current` does not survive the queue boundary

## References

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`patterns.md`](references/patterns.md) | The shallow-job shape, the `_later`/`_now` pair, and the job catalog |
| [`retries-and-context.md`](references/retries-and-context.md) | `retry_on`/`discard_on`/`rescue_from`, carrying request context across the queue |
| [`batching-and-debouncing.md`](references/batching-and-debouncing.md) | Bulk enqueue, avoiding duplicate jobs |
| [`recurring-jobs.md`](references/recurring-jobs.md) | `config/recurring.yml`, scheduled work, testing recurring jobs |
| [`solid-queue.md`](references/solid-queue.md) | Database setup, worker pools, queue priorities, production configuration |
| [`tests.md`](references/tests.md) | Testing model methods directly, asserting enqueues |

## Boundaries

- **Always:** Keep jobs thin (call model methods), follow the `_later`/`_now` naming convention
  (the `_now` suffix is conventional, not enforced), pass records rather than ids, enqueue from
  `after_*_commit`, name the job class only inside the model's `_later` method, declare
  `retry_on`/`discard_on` per job, serialize the context the job needs
- **Ask first:** Before putting logic in a job, before adding a second queue backend, before running
  jobs synchronously in production
- **Profile override:** if the app's `AGENTS.md` records Sidekiq under **Deliberate divergences**,
  that row wins over the Never rule below — write in the idiom the app already runs. Removing it
  is `rich-models-legacy-migration`'s call, not a precondition for the task at hand.
- **Never:** Put business logic in jobs, add Sidekiq, run two queue backends for the same work,
  enqueue from `after_save` (the row may not be committed), rely on ambient `Current` inside `perform`

Rules live in `37signals-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.

See [`08-jobs-async.md`](../../docs/37signals-playbook/08-jobs-async.md).
