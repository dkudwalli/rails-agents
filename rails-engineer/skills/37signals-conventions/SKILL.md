---
name: 37signals-conventions
description: >-
  Applies 37signals-style rich models, resourceful CRUD, model-owned concerns, shallow jobs, and
  incremental service-layer refactoring to ChannelBay. Use for new domain behavior or modernization
  of existing Rails code. WHEN NOT: the work is limited to provider protocol details, frontend
  presentation, operations triage, or test execution without changing application design.
---

# 37signals conventions for ChannelBay

This is the default design direction for ChannelBay, including new behavior and small refactors of
existing code. Read AGENTS.md and the relevant ChannelBay documentation first. Rails 7.1 compatibility
and the explicit platform exceptions below are constraints, not competing architectures.

AGENTS.md is gitignored; if it is absent, say so and ask for it rather than assuming its
constraints.

## Default Rails shape

- Give domain behavior to the owning Active Record model. Keep its associations, scopes, state
  transitions, validation, persistence, and named domain verbs together.
- Split a growing model into small concerns under app/models/model_name/. A model-namespaced concern
  owns the associations, scopes, predicates, and verbs for its feature; reserve app/models/concerns
  for behavior genuinely shared by multiple models.
- Use records for state when the change needs an actor, timestamp, history, or its own resource.
  Favor resourceful routes and CRUD controllers over custom member actions.
- Keep controllers to authentication, merchant-scoped loading, parameter handling, model invocation,
  and response rendering. Scope access through the current merchant or an explicit actor.
- Keep jobs shallow: enqueue at the edge, resolve persisted context, then invoke the model or
  domain API that owns the work.

Read references/incremental-refactoring.md when changing a service-heavy area or introducing a new
domain feature near existing services.

## ChannelBay compatibility boundaries

Do not import 37signals stack preferences that conflict with the application:

- Keep PostgreSQL, integer IDs, Docker Compose, Tailwind v4, esbuild, ViewComponents, Devise,
  CarrierWave, Solid Queue, and Solid Cable.
- Keep provider clients, webhook/SQS orchestration, Python Thrift boundaries, reporting/query
  orchestration, and temporary compatibility facades outside models when that boundary is real.
- Do not use Rails features newer than 7.1 without confirming compatibility.

The existence of app/services is not a reason to place new local domain behavior there. Refactor a
touched service incrementally toward the model that owns the behavior, without a broad rewrite or
changing an established external protocol.
