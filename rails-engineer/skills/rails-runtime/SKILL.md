---
name: rails-runtime
description: >-
  Routes Rails jobs, cache, cable, and background-runtime work to the selected profile. Use when
  working on queues, asynchronous jobs, cache, or realtime infrastructure. WHEN NOT: enabling a
  competing runtime without a recorded profile change.
---

# Rails runtime router

Read AGENTS.md and its Rails Engineer Profile first. Runtime: solid selects solid-queue-setup,
caching-strategies, and layered-job-patterns or rich-models-job-patterns according to architecture.
Runtime: redis-resque selects the conditional 37signals playbook runtime material and
rich-models-job-patterns. Keep the selected runtime coherent; no installer or migration is implied.
