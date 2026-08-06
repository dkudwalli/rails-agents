# 18 — Content, storage & portability

Use Action Text and Active Storage as records owned by the domain. Treat access, retention, storage
accounting, and exportability as product rules — not incidental consequences of attaching a file.

Rails context: [Active Storage Overview](https://guides.rubyonrails.org/active_storage_overview.html)
and [Action Text Overview](https://guides.rubyonrails.org/action_text_overview.html) explain the
underlying Rails features.

---

## Attach content to the model that owns it

Fizzy keeps rich text and an image on `Card`; Writebook keeps a cover on `Book`
(`writebook/app/models/book.rb:5`). The association declares the lifecycle —
`fizzy/app/models/card.rb:11-13`:

```ruby
  has_one_attached :image, dependent: :purge_later

  has_rich_text :description
```

**Rules:**

- Declare rich text and attachments on the owning model, with `purge_later` when attachment removal
  can leave the request path.
- Keep attachment-specific policy beside the model/attachment concern, not in an upload controller.
- Use normal model authorization for content access; an opaque blob URL is not authorization.

## Authorize blobs at the Rails boundary

Fizzy extends Active Storage's controllers instead of replacing Rails routes. It defines access on
the attachment/record, then installs one authorization concern for redirect, proxy, and
representation controllers:

`fizzy/lib/rails_ext/active_storage_authorization.rb:21-56`:

```ruby
included do
  skip_before_action :require_authentication
  before_action :require_authentication, :ensure_accessible, unless: :publicly_accessible_blob?
end

def ensure_accessible
  unless @blob.accessible_to?(Current.user)
    head :forbidden
  end
end

ActiveStorage::Blobs::RedirectController.include ActiveStorage::Authorize
ActiveStorage::Blobs::ProxyController.include ActiveStorage::Authorize
```

**Rules:**

- Give a blob's attachments/records `accessible_to?` and `publicly_accessible?` semantics.
- Apply the policy to every Rails Active Storage serving path, not only to links in views.
- Cache publicly only when the attached record is public (`active_storage_authorization.rb:48-50`).
- Preserve Rails' controllers and attach a named concern through a lifecycle hook.

> Divergence: Fizzy needs tenant-aware attachment authorization. A simple public ONCE deployment can
> use local public storage, as Writebook does (`writebook/config/storage.yml:1-8`), but should not
> accidentally inherit Fizzy's private-content assumptions.

## Store locally by default; make cloud storage an explicit deployment choice

Writebook's local service is a normal application directory:

`writebook/config/storage.yml:1-8`:

```yaml
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

local:
  service: Disk
  root: <%= Rails.root.join("storage", "files") %>
  public: true
```

Fizzy dispatches `storage.yml` to OSS or SaaS configuration (`fizzy/config/storage.yml:1-9`) and
chooses `local` in production until `ACTIVE_STORAGE_SERVICE` says otherwise
(`fizzy/config/environments/production.rb:57-61`).

**Rules:**

- Start with local disk for a self-hostable product and name the persistent directory in deployment.
- Keep credentials in Rails credentials/environment, not `storage.yml`.
- Treat a cloud service as a deploy-time selection; do not couple models to S3.
- Separate test storage from durable local storage.

## Content formats are deliberate domain extensions

Writebook adds Markdown beside Action Text through an explicit concern that declares the paired
association and preload scopes (`writebook/lib/rails_ext/action_text_has_markdown.rb:1-40`). Its
attachment URL extension gives upload names an opaque suffix rather than exposing a raw filename
(`writebook/lib/rails_ext/active_storage_sluggable.rb:1-32`).

**Rules:**

- Extend Action Text/Active Storage only for a concrete product format or URL requirement.
- Make a rich-content extension expose normal model associations and preload scopes.
- Keep a user-visible filename friendly, but make a public upload path unguessable.
- Do not add a second CMS or document store before Action Text plus a small extension fails.

## Portability is a resource and a state machine

Fizzy exposes account exports and imports as REST resources (`fizzy/config/routes.rb:4-11`). Its
export iterates a manifest of record sets (`fizzy/app/models/account/export.rb:1-11`); the manifest
includes domain records, blobs, attachments, rich text, and files
(`fizzy/app/models/account/data_transfer/manifest.rb:25-81`).

`fizzy/app/models/account/import.rb:1-79` uses an attached archive, explicit `pending`/`processing`/
`completed`/`failed` states, a background job, integrity/conflict failures, and completion mail.

**Rules:**

- Model export/import as persisted resources with observable status, not a long controller request.
- Export data and files together, through an explicit ordered manifest.
- Validate before or during import, distinguish expected conflict/integrity failures, and notify the
  user asynchronously.
- Reconcile derived counters and storage totals after importing (`account/import.rb:82-98`).

> Divergence: full account portability is a Fizzy requirement. Add it when users must migrate data,
> not as a generic CRUD feature.

## Related

- [`09-data-search.md`](09-data-search.md) — schema, Action Text, attachments, and database search.
- [`17-realtime-notifications.md`](17-realtime-notifications.md) — export/import completion delivery.
- [`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md) — persistent volume and backups.
