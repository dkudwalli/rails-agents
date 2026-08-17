# Retries and Request Context Reference

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
