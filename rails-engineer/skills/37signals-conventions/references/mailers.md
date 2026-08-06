---
paths:
  - "app/mailers/**/*.rb"
  - "app/views/*_mailer/**/*"
  - "app/channels/**/*.rb"
  - "test/mailers/**/*.rb"
---

# Mailer & Notification Conventions (37signals)

- Mailers are view-backed delivery objects: format and deliver. The logic stays in the model
- Plain-text first; HTML optional with minimal inline CSS
- Bundle notifications — one digest instead of N individual emails
- Transactional email only
- A domain operation selects recipients and enqueues delivery; the mailer does not decide who gets mail
- Always `deliver_later`, never `deliver_now` in production code. See `rules/jobs.md` for the
  `_later`/`_now` chain
- Shared setup lives in `ApplicationMailer`
- Build absolute URLs from configured `default_url_options` — never interpolate a host
- Set one-click unsubscribe headers where the mail is subscribable
- Email previews in `test/mailers/previews/`

## Realtime

- Prefer server-rendered Turbo broadcasts for ordinary UI freshness. Use Action Cable only for a
  small real-time protocol a page refresh cannot express
- Broadcast rendered UI **from the model**, after commit, targeting one named DOM region. Make it
  `*_later` when it becomes slow
- **Authenticate every Cable connection in `Connection`, and authorize every stream through the
  identified actor.** Never stream a client-supplied record id directly
- Channel actions are transport verbs that call a domain operation. No durable domain write hides in
  a chatty channel

## Push

- Persist the subscription and the delivery preference before sending anything
- Queue delivery; send a destination and compact display data, never authority to mutate state
- Keep delivery preferences in the domain model

See [`17-realtime-notifications.md`](../../../docs/37signals-playbook/17-realtime-notifications.md).
