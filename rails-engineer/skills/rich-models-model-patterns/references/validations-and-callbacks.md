# Validations, Callbacks, and Enums Reference

## Validation patterns

```ruby
validates :title, presence: true
validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :email_address, uniqueness: { case_sensitive: false }
validates :user_id, uniqueness: { scope: :card_id }       # Join tables
validates :card, uniqueness: true                          # has_one state records
validates :body, presence: true, if: :published?           # Conditional
```

**A validation is not an invariant.** When a rule is absolute, put a unique index or a database
constraint behind it — a validation only checks the rows Rails happens to look at. See
`rich-models-migration-patterns`.

## Callbacks and enums

Callbacks are for data normalization and for work that genuinely belongs to the record's lifecycle.
Side effects a reader would not expect — emails, API calls, creating unrelated records — belong in an
explicit method the caller invokes.

```ruby
# Lambdas for one-liners; always give a callback an `if:` when it is conditional
before_validation -> { self.title = title.strip }, if: :title_changed?
before_validation :set_default_status, on: :create

# after_*_commit when the work must see committed data -- a worker cannot read an uncommitted row
after_create_commit :broadcast_creation
after_create_commit :notify_recipients_later  # the _later convention

# String enums (preferred for DB readability)
enum :status, {
  draft: "draft", published: "published", archived: "archived"
}, default: :draft, prefix: true
```
