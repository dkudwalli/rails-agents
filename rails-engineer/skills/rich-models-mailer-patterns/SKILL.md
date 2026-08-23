---
name: rich-models-mailer-patterns
description: >-
  Creates minimal Action Mailer classes with bundled notification patterns
  following 37signals conventions. Use when sending emails, creating notification
  systems, digest emails, or when user mentions mailers, emails, notifications,
  or transactional messages.
  Applies only in a rich-models profile app.
  WHEN NOT: A layered profile app — use layered-mailer-patterns. For background job scheduling (use rails-runtime), for event-driven
  triggers (use event-tracking).
compatibility: Ruby 3.3+, Rails 8.0+, Action Mailer, Solid Queue
---

# Mailer Patterns (37signals)

## Philosophy: Minimal Mailers, Bundled Notifications

- Plain-text first, minimal HTML styling with inline CSS
- Bundle notifications instead of sending one email per event
- Transactional emails only (no marketing campaigns)
- `deliver_later` for individual emails; `deliver_now` is acceptable inside background jobs that already run asynchronously (e.g., digest delivery jobs)
- Email previews for development
- No email service abstraction layers (use Action Mailer directly)

**A mailer is a view-backed delivery object.** The domain operation decides *who* gets mail and
enqueues it; the mailer formats and delivers. Shared setup lives in `ApplicationMailer`.

**Build absolute URLs from configured `default_url_options`** — never interpolate a host into a
template. Set one-click unsubscribe headers on anything subscribable, and keep the delivery
preference in the domain model, not in mailer logic.

**Push notifications are a separate opt-in path**, not a mailer variant: persist the subscription and
preference first, queue delivery, and send a destination plus compact display data — never authority
to mutate state.

> Fizzy profile only: account-scoped emails, account context in the from address, and
> account-scoped unsubscribe links. Check the `## Rails Engineer Profile` block in `AGENTS.md`.

## References

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`patterns.md`](references/patterns.md) | `ApplicationMailer`, transactional and digest mailer classes, background delivery from callbacks |
| [`mailer-templates.md`](references/mailer-templates.md) | Paired `.text.erb`/`.html.erb` templates, the mailer layout, button styles, previews |
| [`bundled-notifications.md`](references/bundled-notifications.md) | The notification model, `NotificationBundler`, digest scheduling and templates |
| [`preferences-and-delivery.md`](references/preferences-and-delivery.md) | Per-account email preferences, unsubscribe, `default_url_options` per environment |

## Boundaries

### Always
- Create both `.text.erb` and `.html.erb` templates
- Use `deliver_later` for individual emails; `deliver_now` is acceptable inside background jobs that already run asynchronously (e.g., digest delivery jobs)
- Check user email preferences before sending
- Include unsubscribe links in emails
- Use inline CSS for HTML emails (no external stylesheets)
- Scope emails to account context
- Create email previews for development

### Ask First
- Digest frequency and bundling thresholds
- Whether to include inline attachments (logos)
- SMTP provider configuration

### Never
- Send one email per event (bundle notifications)
- Mix marketing and transactional emails
- Use external CSS in email templates
- Build email service abstraction layers
- Send emails synchronously in request cycle
- Skip email preferences check
- Interpolate a host into a URL instead of using `default_url_options`
- Let the mailer decide who the recipients are

Rules live in `37signals-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.

See [`17-realtime-notifications.md`](../../docs/37signals-playbook/17-realtime-notifications.md).
