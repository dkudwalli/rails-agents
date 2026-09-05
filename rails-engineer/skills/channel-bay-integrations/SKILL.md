---
name: channel-bay-integrations
description: >-
  Guides ChannelBay Shopify, Amazon/SP-API, ShipStation, webhook, SQS, and Python Thrift boundary
  changes. WHEN NOT: the task is not changing or investigating an external-system boundary.
---

# ChannelBay integrations

Read AGENTS.md, then ~/Projects/cb-dev-docs/docs/guides/integrations.md,
guides/api-and-webhooks.md, and the relevant modules page before implementation.

- Keep provider work merchant- and channel-scoped. Preserve credentials and channel polymorphism;
  do not bypass the existing token, channel, and onboarding flows.
- Trace inbound webhooks through their capture, job, service, history, and mutation paths before
  changing parsing or effects. Make duplicate delivery and out-of-order events safe.
- Respect Shopify's documented rate limit and retry behavior. Keep Amazon token refresh, SQS
  processing, reports/feeds, and batch-inventory processing in their established services and jobs.
- Preserve ShipStation webhook authentication and asynchronous order-update flow. Use existing
  external API stubs for tests rather than live provider calls.
- Treat python/ as a separately deployed Thrift service. Keep Rails and Thrift schema/client changes
  compatible and verify the Docker boundary rather than assuming in-process behavior.
- Provider clients and delivery orchestration are legitimate service boundaries. Keep local
  inventory, mapping, and state transitions in the owning models as the surrounding code is touched.
- For inventory mapping work, read the product-mapping documentation first; mapping key and
  source_variant_id semantics matter more than a displayed SKU.

Pair with channel-bay-async for queue behavior, channel-bay-operations for failed syncs, and
channel-bay-testing for provider-safe verification.
