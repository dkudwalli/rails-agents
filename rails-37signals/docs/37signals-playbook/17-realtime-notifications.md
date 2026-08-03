# 17 — Realtime & notifications

Use server-rendered Turbo broadcasts for normal UI freshness. Use Action Cable only when the browser
must send or receive a small real-time protocol that a page refresh cannot express. Mail and push are
delivery mechanisms selected by a model, not competing notification subsystems.

Rails context: [Action Cable Overview](https://guides.rubyonrails.org/action_cable_overview.html) and
[Action Mailer Basics](https://guides.rubyonrails.org/action_mailer_basics.html) describe the framework APIs.

---

## Broadcast rendered UI from the model

Fizzy's notification record makes the state change, then broadcasts the fragment that needs changing:

`fizzy/app/models/notification.rb:21-27, 63-69`:

```ruby
after_create_commit  -> { broadcast_prepend_later_to user, :notifications, target: "notifications" }
after_update_commit  -> { broadcast_update }
after_destroy_commit -> { broadcast_remove_to user, :notifications }

def broadcast_update
  if read?
    broadcast_remove_to(user, :notifications)
  else
    broadcast_prepend_later_to(user, :notifications, target: "notifications")
  end
end
```

**Rules:**

- Make the model own the broadcast because it owns the committed state transition.
- Broadcast after commit, target one named DOM region, and use the server-rendered partial as the
  presentation contract.
- Prefer a Turbo refresh/broadcast before introducing client-side state or a custom channel.
- Keep a change that becomes slow asynchronous (`*_later`); see [`08-jobs-async.md`](08-jobs-async.md).

## Authenticate every Cable connection, then authorize every stream

All three applications reject a connection without a verified session. Campfire's connection is the
smallest representative implementation:

`once-campfire/app/channels/application_cable/connection.rb:1-19`:

```ruby
class Connection < ActionCable::Connection::Base
  include Authentication::SessionLookup

  identified_by :current_user

  def connect
    self.current_user = find_verified_user
  end

  private
    def find_verified_user
      if verified_session = find_session_by_cookie
        verified_session.user
      else
        reject_unauthorized_connection
      end
    end
  end
end
```

Fizzy additionally resolves its account context before assigning the user
(`fizzy/app/channels/application_cable/connection.rb:1-20`).

`once-campfire/app/channels/room_channel.rb:1-13` scopes a room subscription through
`current_user.rooms.find_by`, rejecting an inaccessible requested id.

**Rules:**

- Authenticate in `Connection`; expose only an identified current actor to channels.
- Authorize the stream lookup through that actor. Never stream a client-supplied record id directly.
- Restore required tenant context before resolving the actor.
- Keep channel actions as transport verbs that call a domain operation; do not place business state in
  the channel.

## Channels are for transient collaboration

Campfire uses channels for presence and typing — information that is brief, user-directed, and not a
durable record. Presence updates the membership then broadcasts a compact payload:

`once-campfire/app/channels/presence_channel.rb:1-26`:

```ruby
def present
  membership.present
  broadcast_read_room
end

def broadcast_read_room
  ActionCable.server.broadcast "user_#{current_user.id}_reads", { room_id: membership.room_id }
end
```

`once-campfire/app/channels/typing_notifications_channel.rb:1-13` sends only `:start` / `:stop` and a
small user identity. That is the ceiling: no durable domain write is hidden in a chatty channel.

> Divergence: Campfire has several domain channels; Fizzy and Writebook principally use Cable as the
> transport behind Turbo broadcasts. Introduce a custom channel only for a concrete collaboration
> protocol such as typing or presence.

## Mailers are view-backed delivery objects

Fizzy gives all mailers a sender, layout, shared helpers, and tenant-aware URL options in
`app/mailers/application_mailer.rb:1-15`. A mailer action sets its collaborators and calls `mail`:

`fizzy/app/mailers/export_mailer.rb:1-18`:

```ruby
def completed(export)
  @export = export
  @user = export.user

  mail to: @user.identity.email_address, subject: "Your Fizzy data export is ready for download"
end
```

**Rules:**

- Use an `ApplicationMailer` for shared layout, sender, helpers, and URL policy.
- Have the domain operation select and enqueue mail; keep a mailer action to setup plus rendering.
- Use absolute URLs in mail through configured `default_url_options`, never request-local URL state.
- Add one-click unsubscribe headers for subscription mail
  (`fizzy/app/mailers/concerns/mailers/unsubscribable.rb:1-11`).

## Push is a separate, opt-in delivery path

Campfire queues push when a room receives a message (`once-campfire/app/models/room.rb:46-74`), then
builds a small VAPID payload from a subscription in `lib/web_push/notification.rb:1-28`. The message
record remains canonical; push is a best-effort prompt to return to it.

**Rules:**

- Persist a subscription and user notification preference before attempting push.
- Queue network delivery; do not hold the request open for it.
- Send a destination and compact display data, not authority to mutate application state.
- Keep browser, email, and push delivery preferences in the domain model, not in controllers.

## Related

- [`06-hotwire-javascript.md`](06-hotwire-javascript.md) — Turbo morphing, stream actions, and browser wiring.
- [`10-auth-security.md`](10-auth-security.md) — shared session lookup and credential policy.
- [`11-testing.md`](11-testing.md) — broadcast and mailer test patterns.
