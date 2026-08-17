# Job Patterns Reference

**Tech Stack:** Rails 8.1+, ActiveJob, queue per the app's profile
**Pattern:** Thin jobs call model methods; models have `_later`/`_now` pairs

**Commands:**
```bash
bin/rails generate job NotifyRecipients        # Generate job
bundle exec rake solid_queue:start             # Run worker
bin/rails runner "puts SolidQueue::Job.count"  # Check queue
bin/rails runner "SolidQueue::Job.destroy_all" # Clear jobs
```

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

## Catalog

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
