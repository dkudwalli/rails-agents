---
name: channel-bay-testing
description: >-
  Guides ChannelBay Docker-only verification with Minitest, JavaScript tests, frontend checks, and
  existing test helpers. WHEN NOT: the request does not add, repair, run, or choose verification.
---

# ChannelBay testing

Read AGENTS.md, then these companion documents, before adding or selecting coverage:

- ~/Projects/cb-dev-docs/docs/reference/testing-guide.md
- ~/Projects/cb-dev-docs/docs/modules/testing-checklist.md

- Add new Ruby tests under test/; Minitest is the only suite for new coverage. Do not add files
  under spec/; port an adjacent legacy spec when touching it.
- Reuse nearby inline-record and test/support helpers rather than introducing fixtures or FactoryBot
  to Minitest. Exercise merchant boundaries and external API stubs where relevant.
- Test services, jobs, components, request/Turbo responses, and system behavior at the narrowest
  layer that proves the changed contract. Include duplicate/retry cases for asynchronous provider
  work when behavior can recur.
- Run the project's own verification gate rather than assembling a command list here: the /verify
  skill where the checkout provides one, otherwise the verification order recorded in AGENTS.md.
  Every command runs through Docker Compose; never against Docker-owned host assets.
- The shared remote test database can be unavailable; follow the recorded local DATABASE_URL fallback
  rather than changing test configuration.

Report focused commands and results. Escalate to channel-bay-operations when a failure is
environmental or indicates an existing production workflow problem.
