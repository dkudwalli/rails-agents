# 08 — Background work

Job classes are one line of delegation. The rule that makes that possible is a naming convention.

---

## `_later` enqueues, `_now` performs, and the job knows nothing

`fizzy/STYLE.md:185-214`:

> As a general rule, we write shallow job classes that delegate the logic itself to domain models:
>
> * We typically use the suffix `_later` to flag methods that enqueue a job.
> * A common scenario is having a model class that enqueues a job that, when executed, invokes some
>   method in that same class. In this case, we use the suffix `_now` for the regular synchronous
>   method.
>
> ```ruby
> module Event::Relaying
>   extend ActiveSupport::Concern
>
>   included do
>     after_create_commit :relay_later
>   end
>
>   def relay_later
>     Event::RelayJob.perform_later(self)
>   end
>
>   def relay_now
>     # ...
>   end
> end
>
> class Event::RelayJob < ApplicationJob
>   def perform(event)
>     event.relay_now
>   end
> end
> ```

The real code follows it. `fizzy/app/models/concerns/notifiable.rb:1-22`, in full:

```ruby
module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :source, dependent: :destroy

    after_create_commit :notify_recipients_later
  end

  def notify_recipients
    Notifier.for(self)&.notify
  end

  def notifiable_target
    self
  end

  private
    def notify_recipients_later
      NotifyRecipientsJob.perform_later self
    end
end
```

and the job, `fizzy/app/jobs/notify_recipients_job.rb:1-7`, in full:

```ruby
class NotifyRecipientsJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(notifiable)
    notifiable.notify_recipients
  end
end
```

Four lines of body. **Every job in these apps is this shape**: retry/discard declarations, then
`perform` calling one model method.

Same in campfire — `once-campfire/app/models/room.rb:46-49` and `:72-74`:

```ruby
  def receive(message)
    unread_memberships(message)
    push_later(message)
  end
```
```ruby
    def push_later(message)
      Room::PushMessageJob.perform_later(self, message)
    end
```

fizzy has 13 `*_later` methods across `app/`; campfire has 3; writebook has none (no async work beyond
Active Storage).

**Rules:**
- The `_later` method lives on the model, usually `private`, and is the only place a job class is
  named. Nothing else in the app references `SomeJob`.
- Name the pair after the domain action: `notify_recipients_later` / `notify_recipients`,
  `push_later`, `deliver_later`, `build_later`, `process_later`, `create_mentions_later`,
  `detect_activity_spikes_later`, `clean_inaccessible_data_later`,
  `remove_inaccessible_notifications_later`, `materialize_storage_later`.
- Use `_now` only when the synchronous partner would otherwise collide with the `_later` name.
- `perform` takes records (GlobalID-serialized), not ids.

## Enqueue from `after_*_commit`, never `after_save`

```ruby
    after_create_commit :notify_recipients_later                 # fizzy/app/models/concerns/notifiable.rb:7
    after_create_commit -> { room.receive(self) }                # once-campfire/app/models/message.rb:12
    after_create_commit :create_in_search_index                  # fizzy/app/models/concerns/searchable.rb:7
    after_update_commit :update_in_search_index                  # :8
    after_destroy_commit :remove_from_search_index               # :9
```

A worker in another process can only see committed rows. `after_create` would race.

## Jobs are namespaced under the model that owns them

```
fizzy/app/jobs/account/data_import_job.rb
fizzy/app/jobs/account/incinerate_due_job.rb
fizzy/app/jobs/board/clean_inaccessible_data_job.rb
fizzy/app/jobs/card/activity_spike/detection_job.rb
fizzy/app/jobs/card/clean_inaccessible_data_job.rb
fizzy/app/jobs/card/remove_inaccessible_notifications_job.rb
fizzy/app/jobs/event/webhook_dispatch_job.rb
fizzy/app/jobs/mention/create_job.rb
fizzy/app/jobs/notification/bundle/deliver_all_job.rb
fizzy/app/jobs/notification/bundle/deliver_job.rb
fizzy/app/jobs/notification/push_job.rb
fizzy/app/jobs/webhook/delivery_job.rb
once-campfire/app/jobs/room/push_message_job.rb
once-campfire/app/jobs/bot/webhook_job.rb
```

`Card::CleanInaccessibleDataJob` and `Board::CleanInaccessibleDataJob` coexist because they're
namespaced — the same benefit as namespaced model concerns in [`03-models.md`](03-models.md). Only
genuinely global jobs sit at the top level (`data_export_job.rb`, `delete_unused_tags_job.rb`,
`search_reindex_job.rb`).

## `ApplicationJob` stays a stub

`writebook/app/jobs/application_job.rb:1-7` and `once-campfire/app/jobs/application_job.rb:1-7` are
byte-identical to the Rails generator output, comments and all:

```ruby
class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
```

fizzy adds exactly one line, `fizzy/app/jobs/application_job.rb`:

```ruby
class ApplicationJob < ActiveJob::Base
  prepend AccountTenanted
```

Retry and discard policy is declared **per job** (`discard_on ActiveJob::DeserializationError` in
`notify_recipients_job.rb:2`), not globally — because whether a vanished record is a bug or a normal
race depends on the job.

## Job concerns for cross-cutting context

`fizzy/app/jobs/concerns/account_tenanted.rb:1-38` — how multi-tenancy survives the queue boundary:

```ruby
# Serializes the current account into job data so that jobs run
# within the correct account context via Current.with_account.
#
# Account resolution is deferred to an around_perform callback so
# that missing accounts raise DeserializationError inside the
# execution path where discard_on can handle it.
module AccountTenanted
  extend ActiveSupport::Concern

  prepended do
    attr_reader :account
    around_perform :with_account_context
  end

  def initialize(...)
    super
    @account = Current.account
  end

  def serialize
    super.merge({ "account" => @account&.to_gid })
  end

  def deserialize(job_data)
    super
    @account_gid = job_data["account"]
  end

  private
    def with_account_context(&block)
      resolve_account!

      if account.present?
        Current.with_account(account, &block)
      else
        yield
      end
    end
```

Worth copying wholesale if you have any ambient request context (tenant, locale, actor):

- `prepend` + `prepended do` so `serialize`/`deserialize` wrap ActiveJob's.
- Capture at **enqueue** time in `initialize`, restore at **perform** time in `around_perform`.
- The header comment explains *why* resolution is deferred — so a deleted tenant raises inside the
  path where `discard_on` can catch it. That reasoning is invisible in the code.
- `Current.with_account(account, &block)` — the `with_*` wrapper from
  [`03-models.md`](03-models.md), so context is scoped to the block and always restored.

`fizzy/app/jobs/concerns/smtp_delivery_error_handling.rb` is the other one.

## Bulk enqueueing with `perform_all_later`

`fizzy/app/models/notification/bundle.rb:22-33`:

```ruby
  class << self
    def deliver_all
      due.in_batches do |batch|
        jobs = batch.collect { DeliverJob.new(it) }
        ActiveJob.perform_all_later jobs
      end
    end

    def deliver_all_later
      DeliverAllJob.perform_later
    end
  end
```

Note the two-level pattern: a scheduled job (`DeliverAllJob`) whose only work is to fan out into one
job per record via `ActiveJob.perform_all_later` (a single bulk insert, not N enqueues), batched with
`in_batches` so memory stays flat. `deliver_all_later` exists so the recurring schedule can call it by
name.

## Recurring work is declared in `config/recurring.yml`, mostly as inline commands

`fizzy/config/recurring.yml:1-30`:

```yaml
<% require_relative "../lib/fizzy" %>

production: &production
  # Application functionality: notifications and summaries
  deliver_bundled_notifications:
    command: "Notification::Bundle.deliver_all_later"
    schedule: every 30 minutes

  # Application cleanup
  auto_postpone_all_due:
    command: "Card.auto_postpone_all_due"
    schedule: every hour at minute 50
  delete_unused_tags:
    class: DeleteUnusedTagsJob
    schedule: every day at 04:02

  # Operations cleanup and backups
  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12
  cleanup_webhook_deliveries:
    command: "Webhook::Delivery.cleanup"
    schedule: every 15 minutes
  cleanup_magic_links:
    command: "MagicLink.cleanup"
    schedule: every 4 hours
```

**Rules:**
- Prefer `command:` calling a class method over `class:` naming a job — no job class exists just to be
  scheduled. `class:` is used only where a real job already exists (`DeleteUnusedTagsJob`,
  `Account::IncinerateDueJob`).
- The command is a `*_later` call or a class method, so the schedule tick is instant and the work is
  queued.
- **Stagger the minutes.** `at minute 50`, `at minute 12`, `at minute 20`, `at minute 25`,
  `at minute 16`, `at 04:02` — no two tasks fire together.
- Group with comments by purpose (functionality / cleanup / operations).
- Per-environment YAML anchors, and ERB in the file for conditional entries
  (`fizzy/config/recurring.yml:33-38` adds a metrics task only in SaaS mode).
- Cleanup of the queue's own finished jobs is scheduled like any other chore.
- Every model that accumulates rows gets a `cleanup` class method: `Webhook::Delivery.cleanup`,
  `MagicLink.cleanup`, `Export.cleanup`, `Account::Import.cleanup`.

## Queue configuration

`fizzy/config/queue.yml:1-13`:

```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: [ "default", "solid_queue_recurring", "backend", "webhooks", "*" ]
      threads: 3
      processes: <%= Integer(ENV.fetch("JOB_CONCURRENCY") { Concurrent.physical_processor_count }) %>
      polling_interval: 0.1

development: *default
test: *default
beta: *default
staging: *default
production: *default
```

One worker pool listening to named queues **plus `"*"`**, so a new queue name never silently strands
jobs. Process count derived from the machine (`Concurrent.physical_processor_count`) with an env
override. The same config in every environment — dev runs what production runs.

## The queue backend: the biggest divergence between the three apps

| | fizzy | once-campfire | writebook |
|---|---|---|---|
| Adapter | `:solid_queue` (`config/environments/production.rb:102`) | `:resque` (`production.rb:95`) | `:resque` (`production.rb:65`) |
| Store | the app's database | Redis | Redis |
| Worker process | Solid Queue (or in-Puma via `SOLID_QUEUE_IN_PUMA`) | `resque-pool` | `resque-pool` |
| Recurring | `config/recurring.yml` | — | — |
| Monitoring | `mission_control-jobs` mounted at `/admin/jobs` (`config/routes.rb`) | — | — |

Campfire and writebook run Redis solely for jobs and cache — visible in their `Procfile`:

```
web: bundle exec thrust bin/start-app
redis: redis-server config/redis.conf
workers: FORK_PER_JOB=false INTERVAL=0.1 bundle exec resque-pool
```

Fizzy has no Redis at all: Solid Queue + Solid Cache + Solid Cable put jobs, cache and websockets in
the database.

> Direction of travel: **Solid Queue.** Fizzy is the newest of the three and drops a whole service from
> the deployment. Use Solid Queue on new work; the `_later`/`_now` conventions above are identical
> either way, which is the point — the pattern is adapter-independent.

Fizzy also declares `SOLID_QUEUE_IN_PUMA: true` in `config/deploy.yml` for single-server installs, so a
small deployment runs workers inside the web process and has exactly one process to manage.

## Callback-heavy indexing, still async-friendly

`fizzy/app/models/concerns/searchable.rb:1-33` shows the shape when the work is cheap enough to run
inline but must still be centralised:

```ruby
module Searchable
  extend ActiveSupport::Concern

  SEARCH_CONTENT_LIMIT = 32.kilobytes

  included do
    after_create_commit :create_in_search_index
    after_update_commit :update_in_search_index
    after_destroy_commit :remove_from_search_index
  end

  def reindex
    update_in_search_index
  end

  private
    def create_in_search_index
      if searchable?
        search_record_class.create!(search_record_attributes)
      end
    end

    def update_in_search_index
      if searchable?
        search_record_class.upsert!(search_record_attributes)
      else
        remove_from_search_index
      end
    end
```

and it documents its contract at the bottom (`searchable.rb:56-62`):

```ruby
  # Models must implement these methods:
  # - account_id: returns the account id
  # - search_title: returns title string or nil
  # - search_content: returns content string
  # - search_card_id: returns the card id (self.id for cards, card_id for comments)
  # - search_board_id: returns the board id
  # - searchable?: returns whether this record should be indexed
```

The including model supplies them — `fizzy/app/models/card/searchable.rb:13-31`. **Rule: when a shared
concern requires methods from its includers, list them in a comment at the bottom of the concern.**

## Related

- [`03-models.md`](03-models.md) — the callbacks that trigger `_later` calls.
- [`09-data-search.md`](09-data-search.md) — where the search records go.
- [`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md) — running workers in production.
