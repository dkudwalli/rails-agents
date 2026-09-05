---
name: channel-bay-testing
description: >-
  Guides ChannelBay Docker-only verification with Minitest, JavaScript tests, frontend checks, and
  existing test helpers. WHEN NOT: the request does not add, repair, run, or choose verification.
---

# ChannelBay testing

Read AGENTS.md, ~/Projects/cb-dev-docs/docs/reference/testing-guide.md, and
modules/testing-checklist.md before adding or selecting coverage.

- Add new Ruby tests under test/; Minitest is the only suite for new coverage. Do not add files
  under spec/; port an adjacent legacy spec when touching it.
- Reuse nearby inline-record and test/support helpers rather than introducing fixtures or FactoryBot
  to Minitest. Exercise merchant boundaries and external API stubs where relevant.
- Test services, jobs, components, request/Turbo responses, and system behavior at the narrowest
  layer that proves the changed contract. Include duplicate/retry cases for asynchronous provider
  work when behavior can recur.
- Run all checks through Docker: RuboCop via web, ESLint and Node tests via esbuild, and Rails tests
  via web. Use bin/frontend-check and bin/frontend-audit --check for frontend changes.
- The shared remote test database can be unavailable; follow the recorded local DATABASE_URL fallback
  rather than changing test configuration.

Report focused commands and results. Escalate to channel-bay-operations when a failure is
environmental or indicates an existing production workflow problem.
