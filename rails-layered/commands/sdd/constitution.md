---
description: Create or update the project constitution from interactive or provided principle inputs, ensuring all dependent templates stay in sync.
handoffs: 
  - label: Build Specification
    agent: sdd:specify
    prompt: Implement the feature specification based on the updated constitution. I want to build...
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/sdd-constitution/SKILL.md` in full and execute it.

Everything the user typed after the command is the input that skill asks for.
