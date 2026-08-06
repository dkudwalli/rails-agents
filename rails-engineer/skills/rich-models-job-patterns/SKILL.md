---
name: rich-models-job-patterns
description: >-
  Implements shallow background jobs with _later/_now conventions using Solid
  Queue. Use when adding background processing, async operations, scheduled
  tasks, or when user mentions jobs, queues, workers, or background processing.
  WHEN NOT: Business logic implementation (use model-patterns), controller
  work (use crud-patterns), or mailer delivery (use mailer-patterns).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+, Solid Queue
---

# Job Patterns (37signals)

Jobs orchestrate. Models do the work. Background jobs are thin wrappers around model methods.

> Profile decision: the queue backend is **Solid Queue** (Fizzy, database-backed, no Redis) or
> **Resque + resque-pool** (ONCE-compatible apps, Redis-backed). Solid Queue, Solid Cache, and Solid
> Cable are one runtime decision; Redis, Resque, and resque-pool are one other. Never run both for
> the same work. Sidekiq is not used in either profile. The examples below use Solid Queue — check the
> `## Rails Engineer Profile` block in `AGENTS.md`.

## Project knowledge

**Tech Stack:** Rails 8.1+, ActiveJob, queue per the app's profile
**Pattern:** Thin jobs call model methods; models have `_later`/`_now` pairs

**Commands:**
```bash
bin/rails generate job NotifyRecipients        # Generate job
bundle exec rake solid_queue:start             # Run worker
bin/rails runner "puts SolidQueue::Job.count"  # Check queue
bin/rails runner "SolidQueue::Job.destroy_all" # Clear jobs
```

## The non-negotiables

- **`perform` takes records, not ids.** Active Job serializes them via GlobalID
- **Enqueue from `after_*_commit`, never `after_save`** — a worker can only see committed rows
- **The `_later` method lives on the model**, usually private, and is the *only* place the job class
  is named. Nothing else in the app should reference `NotifyRecipientsJob`
- **Namespace jobs under the model that owns them**: `Event::RelayJob`, `Card::CleanupJob`
- **`ApplicationJob` stays a stub.** Declare `retry_on`/`discard_on` per job, because whether a
  vanished record is a bug depends on the job
- **Serialize the context the job needs.** Ambient `Current` does not survive the queue boundary

## Why shallow jobs

- Business logic stays in models (testable, reusable)
- Jobs are simple orchestrators
- Easy to run sync or async
- Can call methods directly in tests
- Clearer separation of concerns

## Why _later/_now convention

- Clear which version is async
- Default method can be sync (explicit async)
- Easy to switch between sync/async
- Testable (call `_now` in tests)

## Core pattern: shallow job

The job receives a model and calls its `_now` method. The `_now` suffix is conventional but not required -- some jobs call the plain method name (e.g., `notifiable.notify_recipients`).

```ruby
# app/jobs/notify_recipients_job.rb
class NotifyRecipientsJob < ApplicationJob
  queue_as :default

  def perform(notifiable)
    notifiable.notify_recipients_now
  end
end
```

The model defines both `_later` and `_now` methods:

```ruby
# In model or concern
def notify_recipients_later
  NotifyRecipientsJob.perform_later(self)
end

def notify_recipients_now
  recipients.each do |recipient|
    next if recipient == creator
    Notification.create!(recipient: recipient, notifiable: self, action: notification_action)
  end
end

# Default to sync
def notify_recipients
  notify_recipients_now
end

# Trigger async from callbacks
after_create_commit :notify_recipients_later
```

## Job patterns

### Notification job

```ruby
class NotifyRecipientsJob < ApplicationJob
  queue_as :default

  def perform(notifiable)
    notifiable.notify_recipients_now
  end
end
```

### Batch processing job

```ruby
class DeliverBundledNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    Notification::Bundle.deliver_all_now
  end
end
```

### Cleanup job

```ruby
class SessionCleanupJob < ApplicationJob
  queue_as :low_priority

  def perform
    Session.cleanup_old_sessions_now
  end
end
```

### Event tracking job

```ruby
class TrackEventJob < ApplicationJob
  queue_as :default

  def perform(eventable, action, options = {})
    eventable.track_event_now(action, options)
  end
end
```

### Broadcasting job

```ruby
class BroadcastUpdateJob < ApplicationJob
  queue_as :default

  def perform(broadcastable)
    broadcastable.broadcast_update_now
  end
end
```

### External API job

```ruby
class DispatchWebhookJob < ApplicationJob
  queue_as :webhooks
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(webhook, event)
    webhook.dispatch_now(event)
  end
end
```

## Retry and error handling

```ruby
class DispatchWebhookJob < ApplicationJob
  discard_on Webhook::InvalidUrl                              # Don't retry
  retry_on StandardError, wait: :exponentially_longer, attempts: 5  # Backoff
  retry_on CustomError, wait: 5.minutes, attempts: 3          # Fixed interval

  rescue_from Webhook::Timeout do |exception|
    webhook.mark_as_slow!
    raise exception  # Re-raise to trigger retry
  end

  def perform(webhook, event)
    webhook.dispatch_now(event)
  end
end
```

## Request context across the queue boundary

**A job never inherits ambient `Current`.** Deriving context from the job's argument works only when
the argument happens to carry it, which is exactly the case that silently breaks later.

Capture the context at *enqueue* time and restore it at *perform* time, in a job concern applied to
every job that needs it:

```ruby
# app/jobs/concerns/account_tenanted.rb
module AccountTenanted
  extend ActiveSupport::Concern

  included do
    attr_accessor :account_id
  end

  def initialize(...)
    super
    @account_id = Current.account&.id     # captured when the job is created
  end

  def serialize
    super.merge("account_id" => account_id)
  end

  def deserialize(job_data)
    super
    self.account_id = job_data["account_id"]
  end

  def perform_now
    Current.with(account: Account.find(account_id)) { super }
  end
end
```

Then have the test harness blank the ambient account inside `perform_enqueued_jobs`, so any job that
forgot to include the concern fails in the suite rather than in production.

> Fizzy profile only: the account dimension specifically. An ONCE-compatible app has no account layer
> — but the *rule* still holds for whatever request context your jobs depend on.

## Performance patterns

### Batch processing

```ruby
# Enqueue in bulk without loading every record
Card.active.in_batches do |batch|
  ActiveJob.perform_all_later(batch.map { |card| ProcessCardJob.new(card) })
end
```

Give every model that accumulates rows a `cleanup` class method, and drive it from
`config/recurring.yml`.

### Recurring work

```yaml
# config/recurring.yml -- prefer command: over class:, stagger the minutes,
# and group entries by purpose
production:
  cleanup_sessions:
    command: "Session.cleanup"
    schedule: "at 3:07am every day"
  cleanup_magic_links:
    command: "MagicLink.cleanup"
    schedule: "at 3:22am every day"
```

### Queue configuration

One pool listening to the named queues **plus `"*"`**, so a new queue name never silently goes
unprocessed. Process count from `Concurrent.physical_processor_count`. Keep the same configuration
shape in every environment.

### Debouncing (avoid duplicate jobs)

```ruby
def reindex_later
  return if reindex_job_queued?
  ReindexBoardJob.perform_later(id)
end

def reindex_job_queued?
  SolidQueue::Job.exists?(
    job_class: "ReindexBoardJob",
    arguments: [id].to_json,
    finished_at: nil
  )
end
```

## Testing jobs

### Test model methods directly (preferred)

```ruby
class CommentTest < ActiveSupport::TestCase
  test "notify_recipients_now creates notifications" do
    comment = comments(:logo_comment)
    assert_difference -> { Notification.count }, 2 do
      comment.notify_recipients_now
    end
  end
end
```

### Verify job is enqueued

```ruby
class NotifyRecipientsJobTest < ActiveJob::TestCase
  test "enqueues job" do
    comment = comments(:logo_comment)
    assert_enqueued_with job: NotifyRecipientsJob, args: [comment] do
      NotifyRecipientsJob.perform_later(comment)
    end
  end
end
```

### Verify callbacks enqueue jobs

```ruby
test "creating comment enqueues notification job" do
  card = cards(:logo)
  assert_enqueued_with job: NotifyRecipientsJob do
    card.comments.create!(body: "Great work!", creator: users(:david))
  end
end
```

See `references/solid-queue.md` for Solid Queue configuration and
`references/recurring-jobs.md` for recurring job setup.

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

See [`08-jobs-async.md`](../../docs/37signals-playbook/08-jobs-async.md).
