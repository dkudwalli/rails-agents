# 14 — Where the three applications disagree

Do not average the applications into an imaginary standard stack. Start with Fizzy's newer patterns
when building a new multi-user Rails app, but retain the ONCE patterns when their single-tenant
self-hosted constraints match your product.

| Area | Fizzy | Once Campfire | Writebook | Default for new work |
|---|---|---|---|---|
| tenancy | URL-path multi-tenant | one account | one account | Fizzy only when you need multiple accounts |
| primary database | SQLite or MySQL/Trilogy | SQLite | SQLite | SQLite until a real deployment constraint says otherwise |
| primary keys | UUIDv7, base36 | integers | integers | integers unless distributed/non-enumerable IDs are a requirement |
| jobs | Solid Queue | Resque + resque-pool | Resque + resque-pool | Solid Queue |
| cache / cable | Solid Cache / Solid Cable | Redis | Redis | Solid Cache / Solid Cable |
| search | MySQL FTS shards or SQLite FTS5 | SQLite FTS | SQLite FTS | database FTS, adapter-specific implementation |
| deployment | Kamal | ONCE Docker/Procfile | ONCE Docker/Procfile | self-hosted container; Kamal when it fits |
| setup | managed tools, OS packages, optional MySQL | Redis-aware bootstrap | minimal | minimal, then add only needed dependencies |
| written agent guide | broad `STYLE.md` and `AGENTS.md` | none | focused `AGENTS.md` | concise local guidance plus a style source |

## Runtime stack: Solid is the important migration

Fizzy explicitly depends on Solid Cable, Solid Cache and Solid Queue (`fizzy/Gemfile:13-22`) and
configures each against a database (`config/cable.yml:1-15`, `config/cache.yml:1-17`,
`config/queue.yml:1-15`). It has no Redis dependency. Campfire and Writebook instead depend on Redis,
Resque and resque-pool (`once-campfire/Gemfile:10-19`, `writebook/Gemfile:7-16`) and run Redis plus
workers from a Procfile (`once-campfire/Procfile:1-3`, `writebook/Procfile:1-3`).

**Direction of travel:** choose the Solid trifecta for a fresh Rails app. It removes a runtime service
and keeps queue/cache/cable data in the database. Keep Redis/Resque when maintaining the ONCE apps or
when their operational characteristics are specifically needed; do not run both stacks by default.

## Data shape follows tenancy

Campfire and Writebook are unambiguously SQLite-only (`once-campfire/config/database.yml:7-34`,
`writebook/config/database.yml:1-20`). Fizzy dispatches its database config to an adapter-specific
file (`fizzy/config/database.yml:1-8`), ships `sqlite3` and Trilogy (`fizzy/Gemfile:20-22`), and has
UUIDv7 primary keys.

**Direction of travel:** start SQLite/integer IDs for an ONCE-style app. Adopt Fizzy's dual adapter,
UUID, account context and fixture machinery as one coherent multi-tenant package — not as isolated
features to sprinkle into a simple app.

## Routing has the same idea, different exceptions

All three name changes as resources: Fizzy has `resource :closure`, `:goldness`, `:not_now`, `:watch`
and more (`fizzy/config/routes.rb:81-107`); Writebook has `resource :publication` and an `edits`
resource (`writebook/config/routes.rb:22-54`). But Campfire retains a bot endpoint and one custom
collection `clear` route (`once-campfire/config/routes.rb:62-90`). Fizzy also has explicit legacy
redirects and mobile-client routes (`fizzy/config/routes.rb:247-262`).

**Direction of travel:** make normal domain transitions CRUD resources. Keep non-resource routes as
documented integrations, protocol endpoints, or compatibility shims — not convenience verbs.

## Tooling is intentionally uneven

Fizzy's setup is a multi-platform self-hosting script with mise and optional MySQL
(`fizzy/bin/setup:121-195`); Campfire additionally ensures Redis and GitHub Actions linters
(`once-campfire/bin/setup:91-122`); Writebook's setup is a 26-line baseline
(`writebook/bin/setup:1-26`). Fizzy owns the most extensive CI security gate
(`fizzy/config/ci.rb:9-35`); Campfire has the same basic script shape
(`once-campfire/config/ci.rb:3-22`).

**Direction of travel:** prefer Writebook's small scripts. Grow toward Fizzy's operational controls
only when you own the corresponding platforms, environments and release responsibilities.

## How to use this comparison

1. Pick the product boundary first: one self-hosted account or many accounts.
2. Choose one queue/cache/cable family and one deployment flow.
3. Copy the conventions shared by all three without qualification.
4. Record every selected divergence in the target application's `AGENTS.md` so a later contributor
   does not accidentally import a conflicting pattern.
