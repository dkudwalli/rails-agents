---
name: layered-stimulus-patterns
description: >-
  Writes Stimulus controllers with targets, values, actions, and outlets for client-side behaviour Turbo alone cannot express. Use when adding interactive JavaScript, keyboard handling, debouncing, or third-party JS integration. WHEN NOT: Server-rendered partial updates, which belong to Turbo (see layered-turbo-patterns), or pure CSS interactions.
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Stimulus Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`controller-patterns.md`](references/controller-patterns.md) | Controller structure, targets, values, actions, outlets |
| [`accessibility-and-integration.md`](references/accessibility-and-integration.md) | Keyboard support, ARIA, and third-party JS integration |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
