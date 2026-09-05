---
name: rails-guide
description: >-
  Routes a ChannelBay task to the focused implementation, integration, operations, testing, or
  review playbook. Use at the start of work in the ChannelBay repository. WHEN NOT: the task has
  already named the applicable ChannelBay specialist skill.
user-invocable: true
---

# ChannelBay guidance navigator

This pack applies only to ChannelBay. Read the target checkout's AGENTS.md before proposing a
change. It is authoritative for Rails 7.1 compatibility, Docker-only commands, merchant scoping,
and deliberate retained dependencies.

Then read the narrowest applicable document in ~/Projects/cb-dev-docs/docs/:

| Request | Start with |
|---|---|
| New domain behavior or gradual service-to-model modernization | 37signals-conventions |
| Controllers, models, services, schema, permissions, uploads | channel-bay-backend |
| Components, ERB, Tailwind, Turbo, Stimulus, JavaScript | channel-bay-frontend |
| Jobs, queues, recurring work, sync progress, Cable | channel-bay-async |
| Shopify, Amazon, ShipStation, webhooks, SQS, Python Thrift | channel-bay-integrations |
| Incident investigation, logs, stuck syncs, queue recovery | channel-bay-operations |
| New or repaired tests and verification | channel-bay-testing |
| Review, security, tenant safety, regression risk | channel-bay-review |

For work spanning rows, name a primary skill and consult secondary skills in execution order. Start
with 37signals-conventions for new local domain behavior or service-heavy code being touched, then
pair it with the relevant ChannelBay specialist. Do not offer generic Rails onboarding, alternate
stack selection, or migration away from ChannelBay's recorded platform dependencies.
