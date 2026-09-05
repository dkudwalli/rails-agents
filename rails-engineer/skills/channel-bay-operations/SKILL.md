---
name: channel-bay-operations
description: >-
  Guides ChannelBay diagnosis of logs, queues, syncs, webhooks, realtime progress, and safe recovery.
  WHEN NOT: the request is a planned implementation change without an operational symptom.
---

# ChannelBay operations

Read AGENTS.md, then these companion documents:

- ~/Projects/cb-dev-docs/docs/reference/where-to-find-things.md
- ~/Projects/cb-dev-docs/docs/reference/common-errors.md
- ~/Projects/cb-dev-docs/docs/guides/background-jobs.md
- ~/Projects/cb-dev-docs/docs/architecture/solid-queue-tables.md

Start with evidence, not a repair:

1. Identify the merchant, channel, provider, time window, and user-visible symptom.
2. Consult the documented log/history table and feature entrypoint for that symptom.
3. Trace the recorded job, service, webhook, and mutation state before retrying or changing data.
4. Confirm tenant scope and idempotency before any recovery action; do not bulk-replay, delete
   history, or manually mark work complete without an explicit, documented recovery path.

Use the existing error histories, ApplicationLog, queue tables, sync histories, and provider-specific
records to distinguish a stalled queue, failed provider call, bad webhook payload, mapping defect, or
frontend progress issue. Validate configuration-sensitive incidents against config/queue.yml,
config/cable.yml, and the Docker service topology.

Hand implementation fixes to the matching channel-bay specialist skill after the failure mode is
proven.
