# 19 — Integrations & webhooks

Integrations are an untrusted network boundary. Persist their configuration and delivery attempts,
validate destinations, constrain every request, and let a job perform the I/O.

---

## A webhook delivery is a record, not a side effect

Fizzy stores the outbound request/response, state, event, account, and webhook on
`Webhook::Delivery` (`fizzy/app/models/webhook/delivery.rb:1-24`). The record enqueues itself only
after it commits:

```ruby
after_create_commit :deliver_later

def deliver_later
  Webhook::DeliveryJob.perform_later(self)
end

def deliver
  in_progress!
  self.request[:headers] = headers
  self.response = perform_request
  self.state = :completed
  save!
rescue
  errored!
  raise
end
```

**Rules:**

- Record each delivery with a state and its sanitized outcome before/while performing I/O.
- Enqueue only after commit. A webhook describes committed domain state, never a rolled-back change.
- Keep the job shallow: load the delivery and call its domain method.
- Retain an inspectable response summary, but strip signing secrets from stored request headers
  (`fizzy/app/models/webhook/delivery.rb:47-65`).

## Constrain every outbound request

Fizzy gives webhook requests a seven-second timeout, a maximum response size, explicit network error
states, a resolved public IP, and an HMAC signature (`fizzy/app/models/webhook/delivery.rb:4-9,
68-129`). The critical details are explicit:

`fizzy/app/models/webhook/delivery.rb:68-88`:

```ruby
    def perform_request
      if resolved_ip.nil?
        { error: :private_uri }
      else
        request = Net::HTTP::Post.new(uri, headers).tap { |request| request.body = payload }

        response = http.request(request) do |net_http_response|
          stream_body_with_limit(net_http_response)
        end

        { code: response.code.to_i }
      end
    rescue ResponseTooLarge
      { error: :response_too_large }
    rescue Resolv::ResolvTimeout, Resolv::ResolvError, SocketError
      { error: :dns_lookup_failed }
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT
      { error: :connection_timeout }
```

with the limits declared as constants — `fizzy/app/models/webhook/delivery.rb:4-9`:

```ruby
  class ResponseTooLarge < StandardError; end

  STALE_TRESHOLD = 7.days
  USER_AGENT = "fizzy/1.0.0 Webhook"
  ENDPOINT_TIMEOUT = 7.seconds
  MAX_RESPONSE_SIZE = 100.kilobytes
```

Campfire's general HTTP guard resolves the host and rejects private, loopback, link-local, mapped,
and special-use addresses (`once-campfire/lib/restricted_http/private_network_guard.rb:1-75`).

**Rules:**

- Parse and validate URL scheme/host at configuration time, then resolve and validate the actual IP
  immediately before connecting.
- Set open/read timeouts and bound streamed response bytes.
- Classify expected DNS, timeout, connection, TLS, and oversized-response failures; do not collapse
  them into a rescued `nil`.
- Send a stable user agent, content type, timestamp, and HMAC signature. Never log the signing secret.
- Test the private-network and redirect/DNS-rebinding boundary as security code.

## Treat integrations as domain-specific adapters

Fizzy's `Webhook` constrains actions, schemas, and destination types before a delivery exists
(`fizzy/app/models/webhook.rb:1-54`). Its delivery renders a small app template for the integration's
required format (`webhook/delivery.rb:131-185`) rather than exposing internal model serialization.

Campfire's webhook is intentionally a bot conversation: it posts a message payload, accepts a text or
attachment reply, then creates an ordinary message which broadcasts normally
(`once-campfire/app/models/webhook.rb:4-78`).

**Rules:**

- Name integration capabilities in the domain (`subscribed_actions`, supported format, bot user), not
  as controller flags.
- Whitelist supported outgoing events and payload shapes.
- Render an integration payload explicitly; do not make arbitrary internal JSON a public contract.
- Convert an inbound integration response into the same domain object a human action would create.

> Divergence: Fizzy provides managed outbound webhooks with delivery history; Campfire uses per-user
> bot webhooks that can reply into a room; Writebook has no webhook implementation. Choose the
> product contract first — do not install a generic webhook subsystem because another app has one.

## Make the operational surface a resource

Fizzy nests webhooks under boards, gives activation its own resource, and exposes deliveries as JSON
(`fizzy/config/routes.rb:51-56`). This makes configuration, activation, and inspection ordinary
authorized endpoints rather than an admin-only pile of custom verbs.

**Rules:**

- Model integration configuration, activation, and delivery history as separate resources.
- Scope every integration to its owning account/board/user before loading it.
- Keep secrets write-only where possible; expose statuses and summaries, not raw credential material.
- Define deletion/retention explicitly; Fizzy's delivery cleanup deletes stale batches
  (`fizzy/app/models/webhook/delivery.rb:20-27`).

## Related

- [`10-auth-security.md`](10-auth-security.md) — tokens, request authentication, SSRF context, and rate limits.
- [`08-jobs-async.md`](08-jobs-async.md) — background execution and recurring cleanup.
- [`17-realtime-notifications.md`](17-realtime-notifications.md) — turning an accepted bot response into a normal broadcast.
