---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs: 
  - label: Create Tasks
    agent: sdd:tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: sdd:checklist
    prompt: Create a checklist for the following domain...
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/sdd-plan/SKILL.md` in full and execute it.

Everything the user typed after the command is the input that skill asks for.
