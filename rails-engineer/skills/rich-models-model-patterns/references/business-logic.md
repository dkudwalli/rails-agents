# Business Logic Reference

## Action methods (verbs)

```ruby
def close(user: Current.user)
  create_closure!(user: user)
  track_event "card_closed", user: user
  notify_watchers_later
end

def assign(user)
  assignments.create!(user: user) unless assigned_to?(user)
  track_event "card_assigned", particulars: { assignee_id: user.id }
end
```

## Query methods (predicates)

```ruby
def closed?
  closure.present?
end

def assigned_to?(user)
  assignees.include?(user)
end

def can_be_edited_by?(user)
  user.can_administer_card?(self) || creator == user
end
```

## Computed attributes

```ruby
def closed_at
  closure&.created_at
end

def closed_by
  closure&.user
end
```

## _later / _now convention

```ruby
# Async version (queues a job)
def notify_recipients_later
  NotifyRecipientsJob.perform_later(self)
end

# Sync version (immediate execution)
def notify_recipients_now
  recipients.each do |recipient|
    Notification.create!(recipient: recipient, notifiable: self)
  end
end

# Default to sync
def notify_recipients
  notify_recipients_now
end

# Call _later from callbacks
after_create_commit :notify_recipients_later
```

## Using Current for context

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :identity, :account
end

class Card < ApplicationRecord
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :account, default: -> { Current.account }

  def close(user: Current.user)
    create_closure!(user: user)
  end
end
```

`Current` derives dependent attributes in its writers, and offers `with_*` block wrappers rather than
having callers assign attributes ad hoc. **`Current` does not survive a queue boundary** — a job must
be given the context it needs. And it is never a place to keep data that must outlive the request.
