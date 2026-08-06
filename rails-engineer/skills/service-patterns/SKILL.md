---
name: service-patterns
description: >-
  Worked service-object implementations: CRUD, transactional, calculation, and dependency-injected services with the Result type, plus their RSpec specs. Use when writing or testing a concrete service class. WHEN NOT: Deciding which layer a responsibility belongs to (see rails-architecture), the service-layer rules themselves (see layered-conventions), or whether an extraction is warranted yet (see extraction-timing).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Service Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`patterns.md`](references/patterns.md) | Four service shapes with full implementations |
| [`testing.md`](references/testing.md) | RSpec specs for create services, side effects, and transactions |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
