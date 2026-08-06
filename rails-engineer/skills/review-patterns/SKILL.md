---
name: review-patterns
description: >-
  Reviews Rails code against the 37signals playbook: conceptual compression, everything-is-CRUD naming, state as records, authorization by scoping, expanded conditionals. Use when reviewing a diff, PR, or file for playbook conformance, or when the user mentions a review pass or anti-patterns. WHEN NOT: The layered profile, whose service and policy layers this explicitly rejects.
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Review Patterns

Read the file that covers what you are doing rather than all of them.

| Reference | Read it for |
|---|---|
| [`anti-patterns.md`](references/anti-patterns.md) | The catalogue of what to flag, and what to do instead |
| [`review-checklist.md`](references/review-checklist.md) | The pass-by-pass checklist for a review |

These references assume the 37signals profile: rich models, namespaced concerns, state records,
Minitest with fixtures, plain CSS, no service layer. Record which source application you are
following before applying them — see the pack's `AGENTS.md` under Rails Engineer Profile.
