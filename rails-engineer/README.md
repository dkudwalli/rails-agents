# Rails Engineer for ChannelBay

This pack is intentionally narrow: it helps agents make safe changes in ChannelBay, not arbitrary
Rails applications. Start each task in the ChannelBay checkout and invoke rails-guide.

## Skill map

| Need | Skill |
|---|---|
| Find the right playbook and required docs | rails-guide |
| Rich models, resourceful CRUD, service-layer modernization | 37signals-conventions |
| Controllers, models, services, migrations, tenant scope | channel-bay-backend |
| ViewComponents, Tailwind, Turbo, Stimulus, esbuild | channel-bay-frontend |
| Solid Queue, recurring work, Solid Cable | channel-bay-async |
| Shopify, Amazon, ShipStation, webhooks, Python Thrift | channel-bay-integrations |
| Logs, sync recovery, queue and webhook investigation | channel-bay-operations |
| Docker verification, Minitest, JavaScript tests | channel-bay-testing |
| Change and PR risk review | channel-bay-review |

## Source of truth

Read the target checkout's AGENTS.md first. Consult the companion documentation at
~/Projects/cb-dev-docs/docs/ for detail:

- architecture/overview.md, architecture/core-concepts.md, and architecture/database-guide.md for
  domain and persistence.
- guides/workflows.md, guides/background-jobs.md, guides/integrations.md, and
  guides/api-and-webhooks.md for lifecycle and external-system work.
- reference/where-to-find-things.md, reference/common-errors.md, and reference/testing-guide.md for
  diagnosis and verification.
- view-components/ and modules/ for established UI and integration patterns.

The skills point to these sources instead of duplicating fast-changing runbooks.

## Rails design direction

37signals-style Rails is the default for new domain behavior and incremental refactoring: rich models,
model-namespaced concerns, state as records when history matters, resourceful controllers, and shallow
jobs. ChannelBay keeps its deliberate platform choices—PostgreSQL, Tailwind, ViewComponents, Devise,
CarrierWave, Docker, Solid Queue/Cable, and external integration boundaries. Existing services are
refactored a coherent slice at a time, not preserved as the default domain layer or removed wholesale.

## Host compatibility

The pack supports Claude Code and Codex. Codex snapshots a version-pinned payload; reinstall after
the manifest version changes. Validate a release from a clean worktree with
scripts/release_check.sh.
