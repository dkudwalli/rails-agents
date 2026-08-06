---
paths:
  - "app/models/**/*.rb"
  - "app/controllers/**/*.rb"
  - "app/jobs/**/*.rb"
  - "db/migrate/**/*.rb"
  - "config/routes.rb"
---

# Multi-Tenancy Conventions (37signals)

> Fizzy profile only: this entire file. Campfire and Writebook are single-account ONCE applications
> with no account layer at all. Choose multi-tenancy because accounts are first-class in your product,
> not because Fizzy has it — and record the choice in `AGENTS.md` under Rails Engineer Profile.
>
> The hardest thing to retrofit is not the column. It is request and job context. Adding `account_id`
> later, without that context, is named explicitly as a thing not to do.

- URL path-based: `/:account_id/resources`
- `account_id` on every table for data isolation
- Resolve the account **before** authentication; both the account and the user must be active
- All queries scope through `Current.account`; a record outside the account is simply not found
- `belongs_to :account, default: -> { parent.account }` for child models
- **No default scopes for tenancy** — always scope explicitly
- `Current` derives dependent attributes in its writers; offer `with_*` block wrappers rather than
  assigning attributes ad hoc
- **Serialize account context into every job.** A job concern that captures at enqueue and restores at
  perform is the pattern; ambient `Current` does not survive the queue boundary
- Authorize Cable connections and scope every stream through the resolved actor
- Tests must verify cross-account isolation, and the test harness should blank the ambient account
  inside `perform_enqueued_jobs` so a job that forgot to serialize context fails in the suite
- UUIDv7 ids keep account identifiers non-enumerable — adopt them with their fixture and ordering
  implications, not on their own

See [`21-new-app-decisions.md`](../../../docs/37signals-playbook/21-new-app-decisions.md),
[`14-divergences.md`](../../../docs/37signals-playbook/14-divergences.md), and
[`16-configuration-lifecycle.md`](../../../docs/37signals-playbook/16-configuration-lifecycle.md).
