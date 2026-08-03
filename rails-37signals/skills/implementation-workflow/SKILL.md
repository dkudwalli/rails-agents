---
name: implementation-workflow
description: >-
  Routes an implementation task to the right 37signals skill and sequences the work: which pattern skill owns controllers, models, concerns, state records, jobs, or views, and in what order to build. Use when starting a feature and unsure which conventions apply, or when a task spans several areas. WHEN NOT: A single well-scoped change where the governing skill is already obvious.
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Implementation Workflow

Read the file that covers what you are doing rather than all of them.

| Reference | Read it for |
|---|---|
| [`delegation-guide.md`](references/delegation-guide.md) | Which skill owns which kind of task, with worked examples |
| [`workflow-patterns.md`](references/workflow-patterns.md) | How to sequence a feature end to end |

These references assume the 37signals profile: rich models, namespaced concerns, state records,
Minitest with fixtures, plain CSS, no service layer. Record which source application you are
following before applying them — see the pack's `CLAUDE.md` under Application profile.
