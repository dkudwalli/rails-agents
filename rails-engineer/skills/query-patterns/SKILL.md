---
name: query-patterns
description: >-
  Worked query-object implementations: filtering, composition, scopes, N+1 avoidance, and pagination, plus their RSpec specs. Use when writing or testing a concrete query class. Applies only in a layered profile app. WHEN NOT: A rich-models profile app — use rich-models-rails-architecture. Choosing between a scope and a query object (see rails-architecture), the query-layer rules (see layered-conventions), or database-level tuning (see performance-optimization).
compatibility: Ruby 3.3+, Rails 8.0+
---

# Query Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`patterns.md`](references/patterns.md) | Query object shapes, composition, and eager loading |
| [`testing.md`](references/testing.md) | RSpec specs for query objects |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
