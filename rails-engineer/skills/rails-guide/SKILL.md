---
name: rails-guide
description: >-
  Routes a ChannelBay task to the focused implementation, integration, operations, testing, or
  review playbook. Use at the start of work in the ChannelBay repository. WHEN NOT: the task has
  already named the applicable ChannelBay specialist skill.
user-invocable: true
---

# ChannelBay guidance navigator

This pack applies only to ChannelBay. Do not offer generic Rails onboarding, alternate stack
selection, or migration away from ChannelBay's recorded platform dependencies.

## Sources

Read the target checkout's AGENTS.md before proposing a change. It is authoritative for Rails 7.1
compatibility, Docker-only commands, merchant scoping, and deliberate retained dependencies.
AGENTS.md is gitignored; if it is absent, say so and ask for it rather than assuming its
constraints.

The current detailed reference is ~/Projects/cb-dev-docs/docs/, indexed at
~/Projects/cb-dev-docs/docs/home.md. If it is absent, say so before proposing a change that depends
on it. The checkout's own docs/ directory is a mirror of that tree under numbered filenames; prefer
~/Projects/cb-dev-docs/docs/ when the two disagree, including where AGENTS.md points at the mirror.

## Routing

Invoke the narrowest applicable skill below. Each one names the companion documents to read for its
own area, so route first and read from there rather than surveying the documentation here.

| Request | Invoke |
|---|---|
| New domain behavior or gradual service-to-model modernization | 37signals-conventions |
| Controllers, models, services, schema, permissions, uploads | channel-bay-backend |
| Components, ERB, Tailwind, Turbo, Stimulus, JavaScript | channel-bay-frontend |
| Jobs, queues, recurring work, sync progress, Cable | channel-bay-async |
| Shopify, Amazon, ShipStation, webhooks, SQS, Python Thrift | channel-bay-integrations |
| Incident investigation, logs, stuck syncs, queue recovery | channel-bay-operations |
| New or repaired tests and verification | channel-bay-testing |
| Review, security, tenant safety, regression risk | channel-bay-review |

An operational symptom routes to channel-bay-operations even when the failing subsystem is a
provider, a queue, or the sync-progress UI. Reach for channel-bay-integrations,
channel-bay-async, or channel-bay-frontend once operations has proven the failure mode.

For work spanning rows, invoke a primary skill and consult secondary skills in execution order.
Start with 37signals-conventions for new local domain behavior or service-heavy code being touched,
then pair it with the relevant ChannelBay specialist.
