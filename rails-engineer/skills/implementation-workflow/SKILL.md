---
name: implementation-workflow
description: >-
  Routes an implementation task to the right 37signals skill and sequences the work: which pattern skill owns controllers, models, concerns, state records, jobs, or views, and in what order to build. Use when starting a feature and unsure which conventions apply, or when a task spans several areas. Applies only in a rich-models profile app. WHEN NOT: A layered profile app — use rails-workflow. A single well-scoped change where the governing skill is already obvious.
compatibility: Ruby 3.3+, Rails 8.0+
---

# Implementation Workflow

Read the file that covers what you are doing rather than all of them.

| Reference | Read it for |
|---|---|
| [`delegation-guide.md`](references/delegation-guide.md) | Which skill owns which kind of task, with worked examples |
| [`workflow-patterns.md`](references/workflow-patterns.md) | How to sequence a feature end to end |

Read `AGENTS.md` first. These references are conditional on `Architecture: rich-models`: rich
models, namespaced concerns, state records, Minitest with fixtures, plain CSS, and no service layer.
The managed profile and its deliberate divergences decide whether they apply.
