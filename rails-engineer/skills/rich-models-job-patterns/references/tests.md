# Job Testing Reference

## Test model methods directly (preferred)

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

## Verify job is enqueued

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

## Verify callbacks enqueue jobs

```ruby
test "creating comment enqueues notification job" do
  card = cards(:logo)
  assert_enqueued_with job: NotifyRecipientsJob do
    card.comments.create!(body: "Great work!", creator: users(:david))
  end
end
```
