---
name: event-tracking
description: >-
  Builds event tracking, activity feeds, and webhook systems following 37signals
  patterns with a generic Event model and Eventable concern. Use when implementing
  audit trails, activity feeds, event recording, webhooks, or when user mentions
  events, tracking, webhooks, or activity logs.
  WHEN NOT: For state changes as records (use state-records), for background
  job patterns (use rails-runtime), for mailer delivery (use rich-models-mailer-patterns).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+, Solid Queue
---

# Event Tracking

## Philosophy: Generic Event Model + Eventable Concern

- One `Event` model with `action` string and `eventable` polymorphic association
- An `Eventable` concern mixed into models that need tracking
- Models call `track_event("closed", particulars: {...})` in their domain methods
- `particulars` JSON field stores action-specific metadata
- Events drive activity feeds, notifications, and webhook deliveries
- Everything is database-backed (Solid Queue for webhooks, no Redis/Kafka)

## Project Knowledge

**Stack:** Solid Queue for background jobs, Turbo Streams for real-time activity
feed updates, UUIDs for all primary keys, MySQL (SaaS) / SQLite (OSS).

**Multi-tenancy:** All events scoped to account via `account_id`. Events also
scoped to board via `board_id`.

**Commands:**
```bash
# Generate Event model
rails generate model Event action:string eventable:references{polymorphic} \
  board:references creator:references account:references particulars:json

# Generate Webhook models
rails generate model Webhook url:text name:string board:references \
  account:references subscribed_actions:text signing_secret:string active:boolean
rails generate model Webhook::Delivery webhook:references event:references \
  account:references state:string request:text response:text
rails generate model Webhook::DelinquencyTracker webhook:references \
  account:references consecutive_failures_count:integer first_failure_at:datetime
```

## References

Read the file that covers what you are doing rather than all of them.

| Reference | Read it for |
|---|---|
| [`domain-events.md`](references/domain-events.md) | The `Event` model, the `Eventable` concern hierarchy, how models call `track_event`, and `particulars` |
| [`activity-feeds.md`](references/activity-feeds.md) | Events controller, preloading, rendering partials, day timelines, `Event::Description`, fragment caching |
| [`webhooks.md`](references/webhooks.md) | `Webhook`, `Triggerable`, the dispatch job, `Webhook::Delivery`, SSRF protection, delinquency tracking, migrations |

The shape in brief, so you know which file you want:

- `Event` is one generic model — `action` string plus a polymorphic `eventable` — not a class per
  event type. `action.inquiry` gives you `event.action.card_closed?`.
- `Eventable` gives any model `track_event`, which domain methods call directly (`close` tracks
  `:closed`). Models override it with namespaced concerns like `Card::Eventable`.
- `particulars` is a JSON column holding action-specific metadata: `{ old_title:, new_title: }` for
  a rename, `{ assignee_ids: }` for an assignment, `{ column: }` for a triage.
- `after_create` (sync) calls back into the eventable so system comments join the same transaction;
  `after_create_commit` dispatches webhooks asynchronously.
- Events **are** the activity feed — there is no separate `Activity` model.

## The outbound request boundary (SSRF)

**An integration is an untrusted network boundary. Treat this as security code and test it as such.**

A delivery is a **record**, not a side effect: persist the request, the response, and the state, and
enqueue only from `after_create_commit` — a webhook describes committed domain state, never a
rolled-back change. Strip signing secrets from the stored headers.

Constrain every outbound request:

- **Validate the scheme and host at configuration time, then re-validate the *resolved IP*
  immediately before connecting.** A hostname that passed validation can resolve somewhere else a
  moment later — this is DNS rebinding, and checking the hostname does not prevent it
- **Reject private network targets.** Resolve DNS yourself with a timeout and explicit nameservers.
  Cite an RFC per blocklist entry, handle IPv6, and decode NAT64 back to the embedded IPv4
- Re-validate after every redirect, or refuse to follow redirects
- Set open and read timeouts, and bound the number of streamed response bytes
- **Classify failures separately** — DNS, timeout, connection refused, TLS, oversized. Do not collapse
  them into a rescued `nil`; the delivery record should say what actually happened
- Send a stable user agent, a timestamp, and an HMAC signature

Treat integrations as domain-specific adapters: whitelist the supported events and payload shapes,
render the payload explicitly, and convert an inbound integration response into the same domain
object a human action would have created. **Do not make arbitrary internal JSON a public contract.**

Make the operational surface a resource — configuration, activation, and delivery history as separate
scoped endpoints, secrets write-only, retention explicit.

> Do not install a generic webhook subsystem because another application has one. Of the three source
> applications, one has managed outbound webhooks, one has per-user bot webhooks, and one has none.

## Boundaries

### Always
- Use a single generic `Event` model with `action` string and `eventable` polymorphic
- Create an `Eventable` concern -- models call `track_event` in domain methods
- Store action-specific data in `particulars` JSON column
- Persist every delivery as a record, and enqueue it from `after_create_commit`
- Validate the **resolved IP** immediately before connecting, and reject private network targets
- Bound timeouts and response size; classify failures rather than swallowing them
- Include HMAC signature in webhook headers (`X-Webhook-Signature`)
- Strip signing secrets from stored request headers
- Whitelist permitted actions and render the payload explicitly
- Test the private-network and redirect/DNS-rebinding boundary as security code
- Use `after_create` (sync) for side effects that need the transaction (system comments)

### Ask First
- **Whether this application needs a webhook subsystem at all**
- Which business events/actions to track
- Webhook retry strategy and delinquency threshold
- Activity feed pagination and filtering requirements
- Whether events should create system comments on the eventable

### Never
- Create separate model classes per event type (no `CardMoved`, `CommentAdded` models)
- Use external event bus (Kafka, RabbitMQ)
- Track boolean flags instead of event records
- Deliver webhooks synchronously, or enqueue them from `after_save`
- Validate a hostname and then connect to whatever it resolves to
- Rescue an outbound failure to `nil`
- Expose internal JSON as the public payload contract

> Fizzy profile only: account and board scoping on events. An ONCE-compatible app has no account layer.

See [`19-integrations-webhooks.md`](../../docs/37signals-playbook/19-integrations-webhooks.md) and
[`10-auth-security.md`](../../docs/37signals-playbook/10-auth-security.md).
