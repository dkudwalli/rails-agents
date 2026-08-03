---
description: Create or update the feature specification from a natural language feature description.
handoffs: 
  - label: Build Technical Plan
    agent: sdd:plan
    prompt: Create a plan for the spec. I am building with...
  - label: Clarify Spec Requirements
    agent: sdd:clarify
    prompt: Clarify specification requirements
    send: true
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/sdd-specify/SKILL.md` in full and execute it.

Everything the user typed after the command is the input that skill asks for.
