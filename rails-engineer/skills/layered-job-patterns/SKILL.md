---
name: layered-job-patterns
description: >-
  Writes Active Job classes with retry, discard, and idempotency handling, plus their specs. Use when moving work off the request cycle, scheduling recurring work, or when the user mentions background jobs, Solid Queue, retries, or deliver_later. Applies only in a layered profile app. WHEN NOT: A rich-models profile app — use rich-models-job-patterns. Queue adapter setup and operations (see solid-queue-setup), or business logic that belongs in a service the job calls.
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Job Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`patterns.md`](references/patterns.md) | Job structure, retry and discard policy, idempotency |
| [`usage.md`](references/usage.md) | Enqueuing from models, services, and controllers |
| [`tests.md`](references/tests.md) | RSpec specs for jobs |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
