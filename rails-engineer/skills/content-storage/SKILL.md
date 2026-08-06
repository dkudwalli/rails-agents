---
name: content-storage
description: >-
  Handles Action Text rich content, Active Storage attachments as authorized
  domain content, and account export/import as persisted resources. Use when
  adding file uploads, rich text, attachment authorization, image variants, or
  data export/import, or when user mentions Active Storage, Action Text, blobs,
  attachments, uploads, or portability.
  WHEN NOT: Static assets and CSS (use css-design), background job structure
  (use job-patterns), or schema design (use migration-patterns).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+, Action Text, Active Storage
---

# Content, Storage & Portability

Action Text and Active Storage are Rails' own. Do not add a second CMS or document store before
Action Text plus a small extension has actually failed.

## Content belongs to the model that owns it

```ruby
class Card < ApplicationRecord
  has_rich_text :description
  has_many_attached :files, dependent: :purge_later
end
```

Declare rich text and attachments on the owning model, with `dependent: :purge_later`. Keep the
attachment policy — permitted types, size limits, variants — beside the model, not in a controller.

Content-format extensions are deliberate domain decisions: a Markdown concern *beside* Action Text,
an opaque URL slug for an attachment. They are small additions to what Rails gives you, not
replacements for it.

## An opaque blob URL is not authorization

This is the security rule of this skill. A signed blob URL is a capability that leaks by being
forwarded, logged, or indexed. **Authorize every Active Storage serving path.**

Give blobs domain semantics:

```ruby
module Blob::Accessible
  extend ActiveSupport::Concern

  def accessible_to?(user)
    attachments.any? { |attachment| attachment.record.accessible_to?(user) }
  end

  def publicly_accessible?
    attachments.any? { |attachment| attachment.record.publicly_accessible? }
  end
end
```

Then install one authorization concern onto **Rails' own** Redirect, Proxy, and Representation
controllers via a lifecycle hook — rather than replacing Rails' storage routes with your own:

```ruby
# config/initializers/active_storage_authorization.rb
ActiveSupport.on_load(:active_storage_blobs) do
  include Blob::Accessible
end

Rails.application.config.to_prepare do
  ActiveStorage::Blobs::RedirectController.include(BlobAuthorization)
  ActiveStorage::Blobs::ProxyController.include(BlobAuthorization)
  ActiveStorage::Representations::RedirectController.include(BlobAuthorization)
  ActiveStorage::Representations::ProxyController.include(BlobAuthorization)
end
```

**Cache publicly only when the attached record is public.** A private attachment behind a public cache
header is the same leak in a different layer.

## Storage configuration

- **Store locally by default.** Cloud storage is an explicit deployment selection, not a default
- Keep credentials out of `storage.yml`
- Do not couple models to S3 — the model knows about attachments, not about a provider
- Separate test storage from durable storage

> Fizzy profile only: object storage with record-aware authorization for private, tenant-scoped
> content. An ONCE-compatible app serves local instance files, public when the content is public.

## Portability is a resource and a state machine

Export and import are not scripts. Model them as persisted resources with observable status:

```ruby
class Export < ApplicationRecord
  enum :state, %w[pending processing completed failed].index_by(&:itself), default: :pending

  after_create_commit :process_later
end
```

- An **ordered manifest** covering records, blobs, attachments, rich text, and files — in an order the
  import can replay
- Explicit `pending` / `processing` / `completed` / `failed` states, visible to the user
- Asynchronous notification when it finishes
- **Post-import reconciliation** of counters and storage totals — the numbers a live app maintained
  incrementally must be recomputed after a bulk insert
- Bound the work: byte limits, batch sizes, and a retention policy sit next to the operation, and it
  persists enough state to resume

## Boundaries

- **Always:** Declare rich text and attachments on the owning model with `dependent: :purge_later`,
  give blobs `accessible_to?` semantics, authorize every serving path including representations,
  store locally by default, model export/import as resources with explicit states, reconcile counters
  after an import
- **Ask first:** Before selecting cloud storage, before adding a content format beside Action Text,
  before building an export pipeline
- **Never:** Treat an opaque blob URL as authorization, cache a private attachment publicly, replace
  Rails' Active Storage routes, put credentials in `storage.yml`, couple a model to a storage
  provider, add a second CMS or document store by default

See [`18-content-storage-portability.md`](../../docs/37signals-playbook/18-content-storage-portability.md).
