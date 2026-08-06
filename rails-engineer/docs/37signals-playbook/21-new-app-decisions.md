# 21 — Choose a starting profile for a new app

Do not assemble a Rails architecture one gem at a time. Choose one of these coherent profiles first,
then record the product-specific deviations in the target app's `AGENTS.md`.

---

## The two profiles

| | ONCE-compatible profile | Fizzy profile |
|---|---|---|
| Product boundary | One self-hosted account | Multiple accounts, or a credible path to them |
| IDs | Integer | UUIDv7, base36 representation |
| Primary database | SQLite | SQLite or MySQL/Trilogy |
| Request context | `Current.user` / `Current.account` | Account-aware `Current` plus serialized job context |
| Jobs | Resque + resque-pool | Solid Queue |
| Cache / Cable | Redis | Solid Cache / Solid Cable |
| Storage | Local disk, public when the content is public | Local or S3, record-aware authorization when content is private |
| Deployment | Docker + Procfile processes | Kamal + Docker, persisted storage volume |
| Data portability | Back up the instance | Account export/import as a persisted resource |

The ONCE-compatible profile is what Campfire and Writebook actually run: SQLite
(`once-campfire/config/database.yml:7-34`, `writebook/config/database.yml:1-20`), Redis/Resque
(`once-campfire/Gemfile:10-19`, `writebook/Gemfile:7-16`), and three Procfile processes
(`once-campfire/Procfile:1-3`, `writebook/Procfile:1-3`).

The Fizzy profile is one stack: Solid Cable, Cache, and Queue plus SQLite and Trilogy
(`fizzy/Gemfile:13-22`), an account-aware `Current` (`fizzy/app/models/current.rb:1-27`), and
Kamal deployment with a persistent storage volume (`fizzy/config/deploy.yml:17-60`).

## Pick the product boundary first

Choose the **ONCE-compatible profile** when the product is one private installation and it must
operate like Campfire or Writebook — especially when an existing Redis/Resque deployment is part of
the constraint.

Choose the **Fizzy profile** when accounts are first-class, data must remain isolated by account, or
you want the current 37signals database-backed runtime stack. Fizzy can still be deployed as a single
account: `MULTI_TENANT` is a deployment setting, not a reason to add a second stack
(`fizzy/config/deploy.yml:22-35`).

For a new self-hosted product with no ONCE compatibility requirement, take Fizzy's Solid runtime but
keep SQLite and integer ids until a real multi-account or identifier requirement changes them. The
individual choices are deliberate; do not inherit Redis merely because the product is self-hosted.

## Resolve the decisions in this order

| Decision | Choose ONCE-compatible when | Choose Fizzy when | Do not do |
|---|---|---|---|
| Tenancy | One account is a product constraint | Accounts/users need independent ownership and isolation | Add an `account_id` later without request/job context |
| IDs | IDs stay local to one database and can be enumerable | IDs cross boundaries, must not be enumerable, or are created across systems | Add UUIDs without deterministic fixtures and ordering |
| Database | SQLite meets the operational and query need | MySQL is required by the deployment/search workload | Add a database server "for scale" without the requirement |
| Async runtime | Existing ONCE infrastructure requires Redis/Resque | Starting fresh or operating the Solid database runtime | Run Solid Queue and Resque for the same work |
| Cache/Cable | Existing ONCE runtime requires Redis | Starting fresh with the Solid runtime | Keep Redis solely as an unexamined cache default |
| Storage | Public, local instance files are the product fit | Private/tenant-scoped content or object storage is required | Treat an opaque blob URL as authorization |
| Deploy | The ONCE process layout is a compatibility constraint | You operate Kamal and need its deployment/volume model | Combine Procfile workers with `SOLID_QUEUE_IN_PUMA` |

The evidence and caveats behind each row are in [`14-divergences.md`](14-divergences.md),
[`09-data-search.md`](09-data-search.md), [`16-configuration-lifecycle.md`](16-configuration-lifecycle.md),
and [`18-content-storage-portability.md`](18-content-storage-portability.md).

## The non-negotiable combinations

- Solid Queue, Solid Cache, and Solid Cable are one runtime decision. Fizzy configures each against a
  database (`fizzy/config/queue.yml:1-15`, `fizzy/config/cache.yml:1-17`,
  `fizzy/config/cable.yml:1-15`).
- Redis, Resque, and resque-pool are one ONCE operational decision. Do not import only the worker
  command or only the Redis cache setting.
- UUIDv7, fixture ordering, chronological `id` tie-breakers, and account context belong together;
  see [`09-data-search.md`](09-data-search.md) and [`11-testing.md`](11-testing.md).
- Private attachment authorization, tenant-aware routes, and durable storage must be designed as a
  group; see [`18-content-storage-portability.md`](18-content-storage-portability.md) and
  [`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md).

## Record the choice

At the top of a target repository's `AGENTS.md`, record:

```markdown
## Rails Engineer Profile

Profile: Fizzy / ONCE-compatible
Reason: <one product constraint>
Deliberate divergences: <each row above that differs from the profile>
```

That is enough. Do not make a configuration framework or a template generator for two profiles.

## Related

- [`14-divergences.md`](14-divergences.md) — source comparison and direction of travel.
- [`15-review-checklist.md`](15-review-checklist.md) — review the selected runtime as a coherent whole.
- [`README.md`](README.md) — provenance, and how to keep this evidence current when re-vendoring.
