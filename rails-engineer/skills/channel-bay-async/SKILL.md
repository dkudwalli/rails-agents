---
name: channel-bay-async
description: >-
  Guides ChannelBay Solid Queue, recurring job, Solid Cable, and sync-progress changes. WHEN NOT:
  the work is synchronous backend, frontend, external-integration protocol, operations, testing, or
  review work.
---

# ChannelBay asynchronous work

Read AGENTS.md, then these companion documents, before editing jobs, queue configuration, or
realtime updates:

- ~/Projects/cb-dev-docs/docs/guides/background-jobs.md
- ~/Projects/cb-dev-docs/docs/architecture/solid-queue-tables.md

- Use perform_later from request code. Jobs select an explicit queue, guard records deleted before
  execution, and use limits_concurrency when duplicate work would corrupt state or duplicate
  external calls. Keep a job shallow: after resolving persisted context, delegate to the model-owned
  domain action or a real integration boundary.
- Preserve the existing Solid Queue configuration in config/queue.yml; do not substitute Redis,
  Sidekiq, or another queue. Check config/recurring.yml for scheduled behavior.
- Treat sync orchestration, continuation jobs, and mutation jobs as a workflow. Trace the existing
  job, service, and log path before moving work between queues or changing retry behavior.
- Solid Cable is PostgreSQL-backed. Keep connects_to in every config/cable.yml environment and
  preserve merchant-specific sync-progress channels and broadcasts.
- Record useful operational context through the established log/history models; do not mark a sync
  complete until its documented work and continuation conditions have succeeded.

Use channel-bay-integrations for provider protocol changes and channel-bay-operations for an already
failing queue or sync.
