# 01 — Philosophy

The rules in the rest of this playbook are consequences of a handful of beliefs. If you adopt the
rules without the beliefs, they will feel arbitrary and you will abandon them under pressure.

## Code is read far more than it is written, so optimise for reading

`fizzy/STYLE.md:4` states the goal directly:

```
We aim to write code that is a pleasure to read, and we have a lot of opinions about how to do it
well. Writing great code is an essential part of our programming culture, and we deliberately set a
high bar for every code change anyone contributes. We care about how code reads, how code looks,
and how code makes you feel when you read it.
```

This is why the style rules in `02-ruby-style.md` are about *appearance* — method ordering, guard
clauses, indentation under `private`. They exist because a reader scans code top to bottom.

## Consistency beats individual judgement

`fizzy/STYLE.md:8`:

```
When writing new code, unless you are very familiar with our approach, try to find similar code
elsewhere to look for inspiration.
```

**Rule: before writing a new pattern, find the nearest existing example and copy its shape.** This is
the single most load-bearing instruction for an agent working in a codebase like this. Nearly every
kind of thing you need to write already exists somewhere.

## Vanilla Rails: thin controllers, rich models, nothing in between

`fizzy/STYLE.md:155-157`:

```
## Controller and model interactions

In general, we favor a [vanilla Rails](https://dev.37signals.com/vanilla-rails-is-plenty/) approach
with thin controllers directly invoking a rich domain model. We don't use services or other
artifacts to connect the two.
```

Verified structurally: across all three applications `app/` contains exactly these directories —
`assets  channels  controllers  helpers  javascript  jobs  mailers  models  views` (writebook and
fizzy; campfire has no `mailers`). There is no `app/services`, `app/presenters`, `app/serializers`,
`app/forms`, `app/queries`, `app/interactors`, or `app/decorators` in any of them. See
`13-absences.md` for the full list and the evidence.

**But this is not an absolute ban on plain objects.** `fizzy/STYLE.md:179-183`:

```
When justified, it is fine to use services or form objects, but don't treat those as special
artifacts:

```ruby
Signup.new(email_address: email_address).create_identity
```
```

The distinction that matters: a plain object is fine, a *layer* is not. `Signup` lives in
`app/models/signup.rb` alongside `Card` and `Board`, named for a domain concept, not
`SignupService` in a `services/` folder. If you find yourself creating a directory to hold a
category of object, you have built a layer.

## Conceptual compression: one name per concept, and the concept goes in the model

Behaviour is not spread across a controller, a service, a job and a serializer. It is compressed
into one concept that owns its name. `fizzy/app/models/card/closeable.rb:31-48` — closing a card,
entirely:

```ruby
  def close(user: Current.user)
    unless closed?
      transaction do
        not_now&.destroy
        create_closure! user: user
        track_event :closed, creator: user
      end
    end
  end

  def reopen(user: Current.user)
    if closed?
      transaction do
        closure&.destroy
        track_event :reopened, creator: user
      end
    end
  end
```

The controller that exposes it, `fizzy/app/controllers/cards/closures_controller.rb:1-13`:

```ruby
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    capture_card_location
    @card.close
    refresh_stream_if_needed

    respond_to do |format|
      format.turbo_stream
      format.json { head :no_content }
    end
  end
```

The interesting logic is `@card.close`. Everything else in the controller is HTTP.

## Plain Ruby objects are Rails too

Not everything in `app/models` is an Active Record. `fizzy/app/models/color.rb:1-3` is a `Struct`:

```ruby
Color = Struct.new(:name, :value)

class Color
```

Value objects, query objects, parsers and generators live in `app/models/` next to the records —
`fizzy/app/models/time_window_parser.rb`, `fizzy/app/models/signup/account_name_generator.rb`,
`fizzy/app/models/search/query.rb`, `writebook/app/models/html_scrubber.rb`. "Model" means "part of
the domain", not "subclass of ActiveRecord::Base".

## Use the framework's newest capabilities rather than working around them

All three applications run Rails from git (`gem "rails", github: "rails/rails"`), and they use
features as they land: `params.expect` instead of `permit`
(`fizzy/app/controllers/cards_controller.rb:71`), `delegated_type`
(`writebook/app/models/leaf.rb:5`), `broadcasts_refreshes` with page morphing
(`fizzy/app/models/card/broadcastable.rb:5`), `ActiveSupport::ContinuousIntegration` as the CI runner
(`fizzy/config/ci.rb`), `enum` with hash syntax, `Random.uuid`
(`once-campfire/app/models/message.rb:11`).

The practical consequence for you: **prefer the framework's answer over a gem, and prefer the newest
framework answer over the one you learned first.** Also see the warning in `README.md` — some of what
is used here has not shipped in a released Rails yet.

## The app must be deployable by one person onto one machine

Campfire and Writebook are ONCE products: customers buy them and run them on their own server.
`once-campfire/README.md:16-19`:

```
Campfire's Docker image contains everything needed for a fully-functional,
single-machine deployment. This includes the web app, background jobs, caching,
file serving, and SSL. You can use our pre-built image at
`ghcr.io/basecamp/once-campfire:latest`, or build your own from this repo.
```

`once-campfire/Procfile` is the whole production topology:

```
web: bundle exec thrust bin/start-app
redis: redis-server config/redis.conf
workers: FORK_PER_JOB=false INTERVAL=0.1 bundle exec resque-pool
```

This constraint is why the stack looks the way it does — SQLite instead of a database server,
in-database full-text search instead of Elasticsearch, importmap instead of a Node build, Thruster
instead of an Nginx layer, Solid Queue/Cache/Cable in fizzy to remove Redis entirely.

**Rule: prefer the option that adds no new process, no new service, and no new build step.** Every
piece of infrastructure you add is something a person has to operate.

## Simplicity is a decision made repeatedly, not a starting condition

Fizzy is not a small app — 35,478 lines of Ruby, 705 files, multi-tenant, with sharded full-text
search, imports/exports of 500GB ZIPs, passkeys and web push. The absence of service layers and
frontend frameworks is not what a small app looks like; it's what a large app looks like when the
team keeps refusing to add indirection.

## Related

- [`02-ruby-style.md`](02-ruby-style.md) — the appearance rules that "optimise for reading" produces.
- [`03-models.md`](03-models.md) — how "rich domain model" is actually organised so it doesn't become a
  3,000-line class.
- [`13-absences.md`](13-absences.md) — the refusals, with evidence.
