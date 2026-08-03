---
name: controller-patterns
description: >-
  Worked controller implementations: RESTful actions, strong parameters, Pundit authorization, Turbo responses, and error handling, plus request specs. Use when writing or testing a concrete controller. WHEN NOT: The controller-layer rules themselves (see layered-conventions) or deciding what belongs in a controller at all (see rails-architecture).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Controller Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`templates.md`](references/templates.md) | Controller templates for each action and response format |
| [`request-specs.md`](references/request-specs.md) | Request specs covering authorization and responses |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
