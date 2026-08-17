# Email Preferences and Delivery Configuration Reference

## Email preferences and unsubscribe

Keep the delivery preference in the domain model, not in mailer logic.

```ruby
class User < ApplicationRecord
  has_many :email_preferences, dependent: :destroy

  enum :digest_frequency, { never: 0, daily: 1, weekly: 2 }, prefix: true

  def wants_email?(account, type)
    pref = email_preferences.find_by(account: account, preference_type: type)
    pref.nil? || pref.enabled?
  end
end

class EmailPreference < ApplicationRecord
  belongs_to :user
  belongs_to :account

  enum :preference_type, { mentions: 0, comments: 1, assignments: 2, digests: 3 }

  validates :preference_type, uniqueness: { scope: [:user_id, :account_id] }
end
```

## Delivery configuration

`default_url_options` is what makes absolute URLs in templates correct — never interpolate a host.

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.default_url_options = { host: ENV["APP_HOST"] }

# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

# config/environments/test.rb
config.action_mailer.delivery_method = :test
config.action_mailer.default_url_options = { host: "example.com" }
```
