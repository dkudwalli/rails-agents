---
name: rich-models-turbo-patterns
description: >-
  Creates Turbo Streams, Turbo Frames, and morphing patterns for real-time UI
  updates. Use when adding real-time updates, partial page rendering, form
  submissions, or broadcasting.
  Applies only in a rich-models profile app.
  WHEN NOT: A layered profile app — use layered-turbo-patterns. For Stimulus JavaScript controllers (see rails-frontend).
  For general view conventions (see [views reference](../37signals-conventions/references/views.md)).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+, Turbo 8+
---

# Turbo Patterns (37signals)

**Turbo is plenty.** No React, Vue, or Alpine needed. Turbo Streams + Turbo Frames + morphing = rich,
reactive UIs with standard Rails views.

**Reach for `broadcasts_refreshes` with page morphing before writing a broadcast by hand.** Letting
the page re-render and morph is less code than maintaining a stream template per state transition,
and it cannot drift from the page it is updating. Hand-written streams are for the cases morphing
cannot express.

**Broadcast from the model, after commit**, because the model owns the committed state transition —
not from the controller, which only knows about one request. Target one named DOM region. Make it
`*_later` once it becomes slow.

> Profile decision: the cable backend follows the app's profile — Solid Cable (Fizzy,
> database-backed) or Redis (ONCE). It is one decision with the queue and cache, not an independent
> choice. Check the `## Rails Engineer Profile` block in `AGENTS.md`.

## When to use what

| Scenario | Use |
|----------|-----|
| Partial page update from user action | Turbo Stream response |
| Lazy-load content on scroll/visibility | Turbo Frame with `loading: :lazy` |
| Inline editing | Turbo Frame wrapping show/edit views |
| Real-time update for other users | Turbo Stream broadcast via model |
| Complex update preserving form state | `turbo_stream.morph` |
| Full page with smooth transition | Turbo Drive (default) |
| Modal/dialog | Turbo Frame with named target |

## Action Cable security

Turbo's transport is Action Cable, and every stream is an authorization decision.

- **Authenticate the connection** in `ApplicationCable::Connection` — reuse the same session lookup
  concern the controllers use, so there is one definition of "who is this"
- **Authorize every stream through the identified actor.** Never call `stream_for` on a
  client-supplied record id; resolve the record through what the actor can reach
- Restore request/tenant context before resolving the actor
- Channel actions are transport verbs that call a domain operation. No durable domain write should
  live only inside a channel

```ruby
class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user.rooms.find(params[:room_id])   # scoped, not params-trusted
  end
end
```

## References

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`turbo-streams.md`](references/turbo-streams.md) | The seven stream actions, multi-target responses, controller patterns, custom actions |
| [`turbo-frames.md`](references/turbo-frames.md) | Frame targeting, lazy loading, inline editing, modals, nested frames |
| [`broadcasting.md`](references/broadcasting.md) | Model broadcasts, Action Cable setup, Solid Cable, channel patterns |
| [`morphing-and-flash.md`](references/morphing-and-flash.md) | Morph configuration, `data-turbo-permanent`, flash messages |
| [`testing-and-performance.md`](references/testing-and-performance.md) | Controller and system tests for Turbo, lazy loading, broadcast cost |

Useful commands:

```bash
curl -H "Accept: text/vnd.turbo-stream.html" http://localhost:3000/cards
bin/dev
bin/rails test:system
```

## Boundaries

- **Always:** Try `broadcasts_refreshes` with morphing first, broadcast from the model after commit,
  use `dom_id` for element IDs, provide fallback HTML responses, scope every Cable stream through the
  authenticated actor, test Turbo responses
- **Ask first:** Before adding a JS framework, before hand-writing a broadcast that morphing could
  cover, before broadcasting to many users (performance), before using Turbo Frames for navigation
- **Never:** Mix Turbo with client-side rendering frameworks, stream a client-supplied record id,
  hide a durable domain write inside a channel action, forget Turbo Stream format responses,
  broadcast on every keystroke

Rules live in `37signals-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.

See [`06-hotwire-javascript.md`](../../docs/37signals-playbook/06-hotwire-javascript.md) and
[`17-realtime-notifications.md`](../../docs/37signals-playbook/17-realtime-notifications.md).
