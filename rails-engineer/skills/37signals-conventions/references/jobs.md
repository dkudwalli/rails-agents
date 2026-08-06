---
paths:
  - "app/jobs/**/*.rb"
  - "test/jobs/**/*.rb"
---

# Job Conventions (37signals)

- Shallow jobs: a job body is `discard_on`/`retry_on` declarations plus a `perform` that calls one
  model method. Business logic never lives in the job
- Three-part `_later`/`_now` chain:
  1. Model defines `notify_recipients_later` (enqueues) and `notify_recipients_now` (does the work)
  2. `NotifyRecipientsJob#perform(model)` calls `model.notify_recipients_now`
  3. Controllers and callbacks call `model.notify_recipients_later`
- The `_later` method lives on the model, usually private, and is **the only place the job class is
  named**
- `perform` takes records, not ids
- Enqueue from `after_*_commit`, never `after_save` — a worker can only see committed rows
- Namespace jobs under the model that owns them (`Event::RelayJob`)
- `ApplicationJob` stays a stub. Declare `retry_on`/`discard_on` per job, because whether a vanished
  record is a bug depends on the job
- Jobs must be idempotent: safe to run more than once
- **Serialize the context a job needs.** Never rely on ambient `Current` surviving the queue boundary
- Bulk enqueue with `ActiveJob.perform_all_later` inside `in_batches`
- Recurring work goes in `config/recurring.yml`, preferring `command:` over `class:`, with staggered
  minutes; give every model that accumulates rows a `cleanup` class method
- One queue pool listening to named queues **plus `"*"`**, with the same config in every environment
- A shared job concern that requires methods from its includers should list them in a comment at the bottom

> Profile decision: **Solid Queue** (Fizzy, database-backed, no Redis) or **Resque + resque-pool**
> (ONCE apps). Pick one — never run both for the same work. Sidekiq is not used in either profile.

See [`08-jobs-async.md`](../../../docs/37signals-playbook/08-jobs-async.md).
