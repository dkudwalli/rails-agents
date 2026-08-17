# Mailer Patterns Reference

**Stack:** Action Mailer (built-in), background delivery on the app's queue backend,
email previews in development, plain text + HTML multipart emails.

> Fizzy profile only: account-scoped emails, account context in the from address, and
> account-scoped unsubscribe links.

**Commands:**
```bash
rails generate mailer Comment mentioned         # Generate mailer
rails generate mailer Digest daily_activity      # With methods
# Visit http://localhost:3000/rails/mailers      # Preview emails
```

## Simple transactional mailers

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_ADDRESS", "Fizzy <support@fizzy.do>")
  layout "mailer"
end

# app/mailers/comment_mailer.rb
class CommentMailer < ApplicationMailer
  def mentioned(mention)
    @mention = mention
    @comment = mention.comment
    @card = mention.comment.card
    @account = mention.account

    mail(
      to: mention.user.email,
      subject: "#{mention.creator.name} mentioned you in #{@card.title}"
    )
  end

  def new_comment(comment, recipient)
    @comment = comment
    @card = comment.card
    @account = comment.account

    mail(
      to: recipient.email,
      subject: "New comment on #{@card.title}"
    )
  end
end

# app/mailers/membership_mailer.rb
class MembershipMailer < ApplicationMailer
  def invitation(membership)
    @membership = membership
    @account = membership.account
    @inviter = membership.inviter

    mail(
      to: membership.user.email,
      subject: "#{@inviter.name} invited you to #{@account.name}"
    )
  end
end

# app/mailers/card_mailer.rb
class CardMailer < ApplicationMailer
  def assigned(assignment)
    @assignment = assignment
    @card = assignment.card
    @account = assignment.account

    mail(
      to: assignment.user.email,
      subject: "#{assignment.assigner.name} assigned you to #{@card.title}"
    )
  end
end
```

## The digest mailer

The bundling logic that drives these two methods lives in
[`bundled-notifications.md`](bundled-notifications.md).

```ruby
# app/mailers/digest_mailer.rb
class DigestMailer < ApplicationMailer
  def daily_activity(user, account, activities)
    @user = user
    @account = account
    @activities = activities
    @grouped_activities = activities.group_by(&:subject_type)

    mail(
      to: user.email,
      subject: "Daily activity summary for #{account.name}"
    )
  end

  def pending_notifications(user, notifications)
    @user = user
    @notifications = notifications
    @accounts = notifications.map(&:account).uniq

    mail(
      to: user.email,
      subject: "You have #{notifications.size} pending notifications"
    )
  end
end
```

## Background delivery

Always use `deliver_later` in production. Trigger from model callbacks:

```ruby
class Comment < ApplicationRecord
  after_create_commit :notify_subscribers
  after_create_commit :notify_mentions

  private

  def notify_subscribers
    card.subscribers.each do |subscriber|
      next if subscriber == creator
      next unless subscriber.wants_email?(account, :comments)
      CommentMailer.new_comment(self, subscriber).deliver_later
    end
  end

  def notify_mentions
    mentions.each do |mention|
      next unless mention.user.wants_email?(account, :mentions)
      CommentMailer.mentioned(mention).deliver_later
    end
  end
end
```
